// Recall · NodeRepository. Cache-first [D-OFF-1]: serves cached nodes, reconciles
// in the background (server-wins), and raises the tap-to-refresh nudge when the
// server is newer. Scheduling fields are backend-authoritative and are never
// patched by mobile; the cache only mirrors server rows.

import 'dart:async';

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import '../services/sync_status_service.dart';
import 'base_repository.dart';

class NodeRepository extends BaseRepository {
  NodeRepository(SupabaseService supabase, this._local, this._status)
      : super(supabase, 'nodes');

  final LocalStore _local;
  final SyncStatusService _status;

  static const _serverOwnedSchedulingFields = {
    'stability',
    'last_reviewed_at',
    'due_at',
    'reps',
    'lapses',
    'state',
    'last_grade',
    'last_response_ms',
  };

  static String _sig(Node n) =>
      '${n.id}@${n.updatedAt?.toIso8601String() ?? ''}';

  Future<List<Node>> fetchByBucket(String bucketId,
      {bool forceRemote = false}) async {
    if (!_local.isEnabled) return _remoteByBucket(bucketId);

    if (forceRemote) {
      final fresh = await _remoteByBucket(bucketId);
      await _local.replaceNodesForBucket(bucketId, fresh);
      _status.setOffline(false);
      _status.clearUpdates();
      return fresh;
    }

    final cached = await _local.cachedNodesByBucket(bucketId);
    if (cached.isEmpty) return _coldLoad(bucketId);
    unawaited(_reconcile(bucketId, cached));
    return cached;
  }

  Future<List<Node>> _coldLoad(String bucketId) async {
    try {
      final fresh = await _remoteByBucket(bucketId);
      await _local.replaceNodesForBucket(bucketId, fresh);
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

  Future<void> _reconcile(String bucketId, List<Node> cached) async {
    try {
      final fresh = await _remoteByBucket(bucketId);
      _status.setOffline(false);
      await _local.replaceNodesForBucket(bucketId, fresh);
      if (diverged(cached, fresh, _sig)) _status.markUpdatesAvailable();
    } on RepoException catch (e) {
      if (e.isOffline) _status.setOffline(true);
    }
  }

  Future<List<Node>> _remoteByBucket(String bucketId) => guard(() async {
        final rows = await supabase
            .from('nodes')
            .select()
            .eq('bucket_id', bucketId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);
        return mapList(rows, Node.fromJson);
      });

  Future<Node?> fetchById(String id) async {
    final cached = _local.isEnabled ? await _local.cachedNodeById(id) : null;
    if (cached != null) {
      unawaited(_reconcileOne(id));
      return cached;
    }
    return _remoteById(id);
  }

  Future<void> _reconcileOne(String id) async {
    try {
      final fresh = await _remoteById(id);
      if (fresh != null) await _local.upsertNodes([fresh]);
    } on RepoException catch (_) {
      // best-effort; cache keeps serving
    }
  }

  Future<Node?> _remoteById(String id) => guard(() async {
        final row =
            await supabase.from('nodes').select().eq('id', id).maybeSingle();
        return row == null ? null : Node.fromJson(row);
      });

  Future<Node> create(Node node) => guard(() async {
        final row = await supabase
            .from('nodes')
            .insert(writable(node.toJson()))
            .select()
            .single();
        final created = Node.fromJson(row);
        await _local.upsertNodes([created]);
        return created;
      });

  /// Patches client-owned node columns only. Scheduling fields are written by
  /// backend RPCs (`record_review_rpc`, `generate_stack_rpc`) and are stripped.
  Future<Node> update(String id, Map<String, dynamic> changes) =>
      guard(() async {
        final safeChanges = Map<String, dynamic>.from(changes)
          ..removeWhere((key, _) => _serverOwnedSchedulingFields.contains(key));
        if (safeChanges.isEmpty) {
          throw ArgumentError('No client-owned node fields to update.');
        }
        final row = await supabase
            .from('nodes')
            .update(safeChanges)
            .eq('id', id)
            .select()
            .single();
        final updated = Node.fromJson(row);
        await _local.upsertNodes([updated]);
        return updated;
      });

  Future<void> softDelete(String id) => guard(() async {
        await supabase.from('nodes').update(
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
        ).eq('id', id);
        await _local.evictNode(id);
      });

  Future<List<NodeAsset>> fetchAssets(String nodeId) => guard(() async {
        final rows = await supabase
            .from('node_assets')
            .select()
            .eq('node_id', nodeId)
            .order('sort_order', ascending: true);
        return mapList(rows, NodeAsset.fromJson);
      });

  Future<List<Tag>> fetchTags(String userId) => guard(() async {
        final rows = await supabase
            .from('tags')
            .select()
            .eq('user_id', userId)
            .order('name', ascending: true);
        return mapList(rows, Tag.fromJson);
      });
}
