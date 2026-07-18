// Recall · StackRepository. Cache-first [D-OFF-1] for the single active stack +
// its items. Stack generation/membership/order stay backend-authoritative via
// `generate_stack_rpc`; this repo only mirrors the returned rows into the cache
// and raises the tap-to-refresh nudge when the server is newer.

import 'dart:async';

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import '../services/sync_status_service.dart';
import 'base_repository.dart';

typedef StackBuildResult = ({
  Stack? stack,
  List<StackItem> items,
  bool existing,
  String? reason,
});

class StackRepository extends BaseRepository {
  StackRepository(SupabaseService supabase, this._local, this._status)
      : super(supabase, 'stacks');

  final LocalStore _local;
  final SyncStatusService _status;

  static String _sig(Stack? s, List<StackItem> items) {
    final base = s == null
        ? 'none'
        : '${s.id}@${s.updatedAt?.toIso8601String() ?? ''}@${s.status.wire}';
    final itemSig = (items
            .map((i) => '${i.id}:${i.position}:${i.reviewed}')
            .toList()
          ..sort())
        .join(',');
    return '$base|$itemSig';
  }

  /// The single active stack, cache-first with background reconcile.
  Future<Stack?> fetchActive(String userId, {bool forceRemote = false}) async {
    if (!_local.isEnabled) return _remoteActive(userId);

    if (forceRemote) {
      final (stack, items) = await _remoteActiveWithItems(userId);
      await _cacheActive(userId, stack, items);
      _status.setOffline(false);
      _status.clearUpdates();
      return stack;
    }

    final cached = await _local.cachedActiveStack(userId);
    if (cached == null) return _coldLoad(userId);
    unawaited(_reconcile(userId, cached));
    return cached;
  }

  Future<Stack?> _coldLoad(String userId) async {
    try {
      final (stack, items) = await _remoteActiveWithItems(userId);
      await _cacheActive(userId, stack, items);
      _status.setOffline(false);
      return stack;
    } on RepoException catch (e) {
      if (e.isOffline) {
        _status.setOffline(true);
        return null;
      }
      rethrow;
    }
  }

  Future<void> _reconcile(String userId, Stack cached) async {
    try {
      final cachedItems = await _local.cachedStackItems(cached.id);
      final (stack, items) = await _remoteActiveWithItems(userId);
      _status.setOffline(false);
      await _cacheActive(userId, stack, items);
      if (_sig(cached, cachedItems) != _sig(stack, items)) {
        _status.markUpdatesAvailable();
      }
    } on RepoException catch (e) {
      if (e.isOffline) _status.setOffline(true);
    }
  }

  Future<void> _cacheActive(
      String userId, Stack? stack, List<StackItem> items) async {
    if (stack == null) {
      await _local.clearActiveStack(userId);
    } else {
      await _local.upsertActiveStack(stack, items);
    }
  }

  Future<(Stack?, List<StackItem>)> _remoteActiveWithItems(
      String userId) async {
    final stack = await _remoteActive(userId);
    if (stack == null) return (null, const <StackItem>[]);
    final items = await _remoteItems(stack.id);
    return (stack, items);
  }

  Future<Stack?> _remoteActive(String userId) => guard(() async {
        final row = await supabase
            .from('stacks')
            .select()
            .eq('user_id', userId)
            .eq('status', StackStatus.active.wire)
            .maybeSingle();
        return row == null ? null : Stack.fromJson(row);
      });

  /// Recently completed stacks, newest first (for done-fast trailing avg [D-UI-3]).
  Future<List<Stack>> fetchRecentCompleted(String userId, {int limit = 10}) =>
      guard(() async {
        final rows = await supabase
            .from('stacks')
            .select()
            .eq('user_id', userId)
            .eq('status', StackStatus.completed.wire)
            .order('completed_at', ascending: false)
            .limit(limit);
        return mapList(rows, Stack.fromJson);
      });

  Future<StackBuildResult> generate({
    List<String>? scopeBucketIds,
    bool ahead = false,
    int? seed,
  }) =>
      guard(() async {
        final result = await supabase.rpc(
          'generate_stack_rpc',
          params: {
            'scope_bucket_ids': scopeBucketIds,
            'ahead': ahead,
            'seed': seed,
          },
        );
        final parsed = _parseStackBuildResult(asJsonMap(result));
        // Only the persisted active stack is cached; review-ahead stacks aren't.
        final stack = parsed.stack;
        if (!ahead && stack != null) {
          await _local.upsertActiveStack(stack, parsed.items);
        }
        return parsed;
      });

  /// Compatibility wrapper for older callers; still delegates to backend RPC.
  Future<Stack> create(String userId, List<String> scopeBucketIds) =>
      guard(() async {
        final result = await generate(scopeBucketIds: scopeBucketIds);
        final stack = result.stack;
        if (stack == null) {
          throw StateError(result.reason ?? 'No stack generated by backend.');
        }
        return stack;
      });

  Future<void> updateStatus(String stackId, StackStatus status) =>
      guard(() async {
        final changes = <String, dynamic>{'status': status.wire};
        if (status == StackStatus.completed) {
          changes['completed_at'] = DateTime.now().toUtc().toIso8601String();
        }
        await supabase.from('stacks').update(changes).eq('id', stackId);
        // A non-active stack leaves the cached active slot.
        if (status != StackStatus.active) await _local.evictStack(stackId);
      });

  /// Abandon an active stack mid-session. Clears cooldown on scope buckets that
  /// still have due cards so Today shows remaining work (S11 / engine §10.14).
  Future<void> abandon(String stackId) => guard(() async {
        await supabase.rpc('abandon_stack_rpc', params: {'p_stack_id': stackId});
        await _local.evictStack(stackId);
      });

  Future<List<StackItem>> fetchItems(String stackId,
      {bool forceRemote = false}) async {
    if (!_local.isEnabled) return _remoteItems(stackId);

    if (!forceRemote) {
      final cached = await _local.cachedStackItems(stackId);
      if (cached.isNotEmpty) {
        unawaited(_reconcileItems(stackId, cached));
        return cached;
      }
    }
    final fresh = await _remoteItems(stackId);
    await _local.replaceStackItems(stackId, fresh);
    return fresh;
  }

  Future<void> _reconcileItems(String stackId, List<StackItem> cached) async {
    try {
      final fresh = await _remoteItems(stackId);
      _status.setOffline(false);
      await _local.replaceStackItems(stackId, fresh);
      if (_sig(null, cached) != _sig(null, fresh)) {
        _status.markUpdatesAvailable();
      }
    } on RepoException catch (e) {
      if (e.isOffline) _status.setOffline(true);
    }
  }

  Future<List<StackItem>> _remoteItems(String stackId) => guard(() async {
        final rows = await supabase
            .from('stack_items')
            .select()
            .eq('stack_id', stackId)
            .order('position', ascending: true);
        return mapList(rows, StackItem.fromJson);
      });

  /// Stack items are created by `generate_stack_rpc`; this method only exists to
  /// fail fast if legacy code tries to write client-selected items.
  Future<List<StackItem>> addItems(List<StackItem> items) => guard(() async {
        throw UnsupportedError(
          'stack_items are backend-authoritative; call generate() instead.',
        );
      });

  Future<void> markItemReviewed(String itemId) async {
    if (_local.isEnabled) await _local.setStackItemReviewed(itemId, true);
    try {
      await guard(() async {
        await supabase
            .from('stack_items')
            .update({'reviewed': true}).eq('id', itemId);
      });
    } on RepoException catch (e) {
      if (!e.isOffline) rethrow; // offline: cache already reflects it
    }
  }

  StackBuildResult _parseStackBuildResult(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return (
      stack: json['stack'] == null
          ? null
          : Stack.fromJson(asJsonMap(json['stack'])),
      items: rawItems is List
          ? rawItems.map((i) => StackItem.fromJson(asJsonMap(i))).toList()
          : const <StackItem>[],
      existing: asBool(json['existing']),
      reason: asStringOrNull(json['reason']),
    );
  }
}
