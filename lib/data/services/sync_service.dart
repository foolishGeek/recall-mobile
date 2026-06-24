// Recall · SyncService. Replays the append-only offline review queue [D-OFF-1]:
// drains pending reviews in `client_timestamp` order through the backend
// `record_review_rpc` (server time authoritative; node state is a deterministic
// function of the ordered review log). Dedupe is by idempotency key — a replay
// the server already has (UNIQUE violation → `conflict`) is dropped. A failed
// event stays queued and the others continue (sprint §7). No scheduling math
// happens here; the server returns the recomputed node, which we cache.

import 'package:sentry_flutter/sentry_flutter.dart';

import '../local/local_store.dart';
import '../models/models.dart';
import 'repo_exception.dart';
import 'supabase_service.dart';
import 'sync_status_service.dart';

class SyncService {
  SyncService(this._supabase, this._local, this._status);

  final SupabaseService _supabase;
  final LocalStore _local;
  final SyncStatusService _status;

  bool _draining = false;

  /// Flushes queued profile preference writes (e.g. onboarding_done). Safe to
  /// call before AuthGate hydration on cold start.
  Future<void> flushProfilePrefs() async {
    if (!_local.isEnabled) return;
    if (_supabase.currentUserId == null) return;
    await _flushProfilePrefs();
  }

  /// Replays every queued review in order. Re-entrant-safe: a second call while
  /// a drain is in flight returns immediately. Stops early (keeping the backlog)
  /// when the network drops; the connectivity listener resumes it on reconnect.
  Future<void> drain() async {
    if (!_local.isEnabled || _draining) return;
    if (_supabase.currentUserId == null) return;

    _draining = true;
    _status.setSyncing(true);
    try {
      final pending = await _local.pendingInOrder();
      for (final entry in pending) {
        final keepGoing = await _replayOne(entry);
        if (!keepGoing) break;
      }
      await _flushProfilePrefs();
    } finally {
      _draining = false;
      _status.setSyncing(false);
      _status.setPendingCount(await _local.pendingCount());
    }
  }

  Future<void> _flushProfilePrefs() async {
    final pending = await _local.pendingProfilePrefs();
    for (final entry in pending) {
      try {
        await _supabase
            .from('profiles')
            .update(entry.changes)
            .eq('id', entry.userId);
        await _local.removePendingProfilePrefs(entry.userId);
      } catch (e, st) {
        final mapped = mapError(e, st);
        if (mapped.isOffline) return;
        await Sentry.captureException(
          mapped.cause ?? mapped,
          stackTrace: mapped.causeStackTrace ?? st,
          withScope: (scope) => scope.setTag('feature', 'sync_profile_prefs'),
        );
      }
    }
  }

  /// Returns false to stop the drain (network dropped); true to continue.
  Future<bool> _replayOne(PendingReviewEntry entry) async {
    try {
      final result = await _supabase.rpc(
        'record_review_rpc',
        params: {'payload': _rpcPayload(entry.review)},
      );
      final map = asJsonMap(result);
      final nodeJson = map['node'];
      if (nodeJson is Map) {
        await _local.upsertNodes([Node.fromJson(asJsonMap(nodeJson))]);
      }
      await _local.removePending(entry.clientUuid);
      // Server recomputed scheduling/streak/XP → screens may be stale.
      _status.markUpdatesAvailable();
      return true;
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.conflict) {
        // Idempotent: the server already recorded this review → drop it.
        await _local.removePending(entry.clientUuid);
        return true;
      }
      if (e.code == RepoErrorCode.offline) {
        return false; // keep the backlog; resume on reconnect
      }
      await _captureFailure(entry, e, null);
      return true; // keep this one queued, continue the rest
    } catch (e, st) {
      await _captureFailure(entry, e, st);
      return true;
    }
  }

  Future<void> _captureFailure(
    PendingReviewEntry entry,
    Object error,
    StackTrace? st,
  ) async {
    await _local.markPendingAttempt(entry.clientUuid, error.toString());
    await Sentry.captureException(
      error,
      stackTrace: st,
      withScope: (scope) {
        scope.setTag('feature', 'sync');
        scope.setContexts('sync', {'idempotency_key': entry.idempotencyKey});
      },
    );
  }

  /// Mirrors `BaseRepository.writable`: drops nulls + server-managed keys so the
  /// RPC payload matches the direct online path.
  Map<String, dynamic> _rpcPayload(Review review) {
    final out = <String, dynamic>{};
    review.toJson().forEach((key, value) {
      if (value == null) return;
      if (key == 'id' || key == 'created_at') return;
      out[key] = value;
    });
    return out;
  }
}
