// Recall · BucketRepository. Cache-first [D-OFF-1]: serves the Drift cache
// immediately, reconciles with the server in the background (server-wins), and
// raises the tap-to-refresh nudge when the server is newer. Active-bucket scope
// stays server-authoritative (tier-aware RPC) with a cache fallback offline.
// Bucket CRUD (soft-delete) + mastery/heat views return models / typed records.

import 'dart:async';

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import '../services/sync_status_service.dart';
import 'base_repository.dart';

/// Fresh per-bucket heat stats from `v_bucket_heat`.
typedef BucketHeatStats = ({
  int nodeCount,
  int dueCount,
  int dominantPriority,
});

class BucketRepository extends BaseRepository {
  BucketRepository(SupabaseService supabase, this._local, this._status)
      : super(supabase, 'buckets');

  final LocalStore _local;
  final SyncStatusService _status;

  static String _sig(Bucket b) =>
      '${b.id}@${b.updatedAt?.toIso8601String() ?? ''}';

  /// Tier-aware active buckets via `active_buckets_for_user`. Server-authoritative
  /// (tier gate); falls back to the full cached set only when offline.
  Future<List<Bucket>> fetchActiveBuckets(String userId) async {
    try {
      return await _remoteActiveBuckets(userId);
    } on RepoException catch (e) {
      if (e.isOffline && _local.isEnabled) {
        _status.setOffline(true);
        return _local.cachedBuckets(userId);
      }
      rethrow;
    }
  }

  Future<List<Bucket>> _remoteActiveBuckets(String userId) => guard(() async {
        final res = await supabase.rpc(
          'active_buckets_for_user',
          params: {'uid': userId},
        );
        return mapList((res as List?) ?? const [], Bucket.fromJson);
      });

  /// All non-deleted buckets, cache-first with background reconcile.
  Future<List<Bucket>> fetchAll(String userId, {bool forceRemote = false}) async {
    if (!_local.isEnabled) return _remoteAll(userId);

    if (forceRemote) {
      final fresh = await _remoteAll(userId);
      await _local.replaceBuckets(userId, fresh);
      _status.setOffline(false);
      _status.clearUpdates();
      return fresh;
    }

    final cached = await _local.cachedBuckets(userId);
    if (cached.isEmpty) return _coldLoad(userId);
    unawaited(_reconcile(userId, cached));
    return cached;
  }

  Future<List<Bucket>> _coldLoad(String userId) async {
    try {
      final fresh = await _remoteAll(userId);
      await _local.replaceBuckets(userId, fresh);
      _status.setOffline(false);
      return fresh;
    } on RepoException catch (e) {
      if (e.isOffline) {
        _status.setOffline(true);
        return const [];
      }
      rethrow;
    }
  }

  Future<void> _reconcile(String userId, List<Bucket> cached) async {
    try {
      final fresh = await _remoteAll(userId);
      _status.setOffline(false);
      await _local.replaceBuckets(userId, fresh);
      if (diverged(cached, fresh, _sig)) _status.markUpdatesAvailable();
    } on RepoException catch (e) {
      if (e.isOffline) _status.setOffline(true);
      // non-offline failures are already captured by `guard`; keep serving cache
    }
  }

  Future<List<Bucket>> _remoteAll(String userId) => guard(() async {
        final rows = await supabase
            .from('buckets')
            .select()
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);
        return mapList(rows, Bucket.fromJson);
      });

  Future<Bucket?> fetchById(String id) async {
    final cached = _local.isEnabled ? await _local.cachedBucketById(id) : null;
    if (cached != null) {
      unawaited(_reconcileOne(id));
      return cached;
    }
    return _remoteById(id);
  }

  Future<void> _reconcileOne(String id) async {
    try {
      final fresh = await _remoteById(id);
      if (fresh != null) await _local.upsertBuckets([fresh]);
    } on RepoException catch (_) {
      // best-effort; cache keeps serving
    }
  }

  Future<Bucket?> _remoteById(String id) => guard(() async {
        final row =
            await supabase.from('buckets').select().eq('id', id).maybeSingle();
        return row == null ? null : Bucket.fromJson(row);
      });

  Future<Bucket> create(Bucket bucket) => guard(() async {
        final row = await supabase
            .from('buckets')
            .insert(writable(bucket.toJson(),
                drop: {'id', 'created_at', 'updated_at', 'heat_summary'}))
            .select()
            .single();
        final created = Bucket.fromJson(row);
        await _local.upsertBuckets([created]);
        return created;
      });

  Future<Bucket> update(String id, Map<String, dynamic> changes) =>
      guard(() async {
        final row = await supabase
            .from('buckets')
            .update(changes)
            .eq('id', id)
            .select()
            .single();
        final updated = Bucket.fromJson(row);
        await _local.upsertBuckets([updated]);
        return updated;
      });

  Future<void> softDelete(String id) => guard(() async {
        await supabase.from('buckets').update(
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
        ).eq('id', id);
        await _local.evictBucket(id);
      });

  /// Difficulty-weighted mastery % from `v_bucket_mastery` [D-VIEW-1].
  Future<double?> fetchMastery(String bucketId) => guard(() async {
        final row = await supabase
            .from('v_bucket_mastery')
            .select('mastery_pct')
            .eq('bucket_id', bucketId)
            .maybeSingle();
        return row == null ? null : asDoubleOrNull(row['mastery_pct']);
      });

  Future<BucketHeatStats?> fetchHeatStats(String bucketId) => guard(() async {
        final row = await supabase
            .from('v_bucket_heat')
            .select('node_count, due_count, dominant_priority')
            .eq('bucket_id', bucketId)
            .maybeSingle();
        if (row == null) return null;
        return (
          nodeCount: asInt(row['node_count']),
          dueCount: asInt(row['due_count']),
          dominantPriority: asInt(row['dominant_priority'], 1),
        );
      });

  // --------------------------------------------------------- batch (S12) --

  /// All mastery values in one query, keyed by bucket_id.
  Future<Map<String, double>> fetchAllMastery(String userId) => guard(() async {
        final rows = await supabase
            .from('v_bucket_mastery')
            .select('bucket_id, mastery_pct')
            .eq('user_id', userId);
        final map = <String, double>{};
        for (final r in rows) {
          final id = asString(r['bucket_id']);
          final pct = asDoubleOrNull(r['mastery_pct']);
          if (id.isNotEmpty && pct != null) map[id] = pct;
        }
        return map;
      });

  /// All heat stats in one query, keyed by bucket_id.
  Future<Map<String, BucketHeatStats>> fetchAllHeatStats(String userId) =>
      guard(() async {
        final rows = await supabase
            .from('v_bucket_heat')
            .select('bucket_id, node_count, due_count, dominant_priority')
            .eq('user_id', userId);
        final map = <String, BucketHeatStats>{};
        for (final r in rows) {
          final id = asString(r['bucket_id']);
          if (id.isEmpty) continue;
          map[id] = (
            nodeCount: asInt(r['node_count']),
            dueCount: asInt(r['due_count']),
            dominantPriority: asInt(r['dominant_priority'], 1),
          );
        }
        return map;
      });

  /// Total node count across all user buckets from `v_bucket_heat`.
  Future<int> fetchTotalNodeCount(String userId) => guard(() async {
        final rows = await supabase
            .from('v_bucket_heat')
            .select('node_count')
            .eq('user_id', userId);
        var total = 0;
        for (final r in rows) {
          total += asInt(r['node_count']);
        }
        return total;
      });

  /// Next drop time per bucket via `next_drop_time_rpc`. When [bucketIds] is
  /// empty the RPC is called once with NULL (global next drop).
  Future<Map<String, DateTime>> fetchNextDropTimes(
    List<String> bucketIds,
  ) async {
    final map = <String, DateTime>{};
    final futures = bucketIds.map((id) => _fetchNextDrop(id));
    final results = await Future.wait(futures);
    for (var i = 0; i < bucketIds.length; i++) {
      if (results[i] != null) map[bucketIds[i]] = results[i]!;
    }
    return map;
  }

  Future<DateTime?> _fetchNextDrop(String bucketId) async {
    try {
      return await guard(() async {
        final res = await supabase.rpc(
          'next_drop_time_rpc',
          params: {'bucket_id': bucketId},
        );
        return asDateTime(res);
      });
    } on RepoException catch (_) {
      return null;
    }
  }
}
