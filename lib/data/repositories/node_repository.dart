// Recall · NodeRepository. Cache-first [D-OFF-1]: serves cached nodes, reconciles
// in the background (server-wins), and raises the tap-to-refresh nudge when the
// server is newer. Scheduling fields are backend-authoritative and are never
// patched by mobile; the cache only mirrors server rows.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

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
            .order('comfort', ascending: false);
        return mapList(rows, Node.fromJson);
      });

  /// Cache-first by default `[D-OFF-1]`. Pass [forceRemote] for one-shot reads
  /// that must not show a stale body (e.g. review session after Aura Apply).
  Future<Node?> fetchById(String id, {bool forceRemote = false}) async {
    if (forceRemote) {
      try {
        final fresh = await _remoteById(id);
        if (fresh != null && _local.isEnabled) {
          await _local.upsertNodes([fresh]);
        }
        if (fresh != null) return fresh;
      } on RepoException catch (e) {
        if (!e.isOffline) rethrow;
        // Offline: fall through to cache.
      }
    }

    final cached = _local.isEnabled ? await _local.cachedNodeById(id) : null;
    if (cached != null) {
      if (!forceRemote) unawaited(_reconcileOne(id));
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

  /// Tags attached to a specific node via the `node_tags` join table.
  Future<List<Tag>> fetchTagsForNode(String nodeId) => guard(() async {
        final rows = await supabase
            .from('node_tags')
            .select('tag_id, tags(id, user_id, name, created_at)')
            .eq('node_id', nodeId);
        return rows
            .where((r) => r['tags'] != null)
            .map((r) => Tag.fromJson(Map<String, dynamic>.from(r['tags'] as Map)))
            .toList();
      });

  /// Per-node heat percentage (0-100) from backend `node_heat_pct` RPC.
  /// Falls back to a client-side heuristic when offline.
  Future<double> fetchHeatPct(String nodeId) => guard(() async {
        final result = await supabase.rpc(
          'node_heat_pct',
          params: {'p_node_id': nodeId},
        );
        return asDouble(result);
      });

  /// Whether this node has at least one review row (controls comfort read-only).
  Future<bool> hasReviews(String nodeId) => guard(() async {
        final rows = await supabase
            .from('reviews')
            .select('id')
            .eq('node_id', nodeId)
            .limit(1);
        return (rows as List).isNotEmpty;
      });

  /// AI model display labels from `app_config` (shared with BucketRepository).
  Future<Map<String, String>> fetchAiModelLabels() => guard(() async {
        final rows = await supabase
            .from('app_config')
            .select('key, value')
            .inFilter('key', ['ai_model_free', 'ai_model_premium']);
        final map = <String, String>{};
        for (final r in rows) {
          final k = asString(r['key']);
          final v = r['value'];
          if (k.isNotEmpty) {
            map[k] = v is String ? v : v.toString();
          }
        }
        return map;
      });

  /// Fetch the parent bucket's name for display in the top bar.
  Future<String?> fetchBucketName(String bucketId) => guard(() async {
        final row = await supabase
            .from('buckets')
            .select('name')
            .eq('id', bucketId)
            .maybeSingle();
        return row == null ? null : asString(row['name']);
      });

  /// Generates a signed URL for a private Storage object. The bucket name is
  /// inferred from the asset's MIME type (pdf → `node-pdfs`, image → `node-images`).
  Future<String> signAssetUrl(String storagePath, String mimeType) async {
    final bucket = mimeType.contains('pdf') ? 'node-pdfs' : 'node-images';
    final result = await supabase.client.storage
        .from(bucket)
        .createSignedUrl(storagePath, 3600);
    return result;
  }

  // ── S15: Add/Edit Node helpers ──

  /// Upsert a tag by name (unique on lower(name) per user).
  Future<Tag> createTag(String userId, String name) => guard(() async {
        final trimmed = name.trim().toLowerCase();
        final existing = await supabase
            .from('tags')
            .select()
            .eq('user_id', userId)
            .ilike('name', trimmed)
            .maybeSingle();
        if (existing != null) return Tag.fromJson(existing);
        final row = await supabase
            .from('tags')
            .insert({'user_id': userId, 'name': trimmed})
            .select()
            .single();
        return Tag.fromJson(row);
      });

  /// Replace all node_tags for a node with the given tag IDs (diff-based).
  Future<void> syncNodeTags(String nodeId, List<String> tagIds) =>
      guard(() async {
        await supabase.from('node_tags').delete().eq('node_id', nodeId);
        if (tagIds.isEmpty) return;
        final rows = tagIds
            .map((tid) => {'node_id': nodeId, 'tag_id': tid})
            .toList();
        await supabase.from('node_tags').insert(rows);
      });

  /// Insert a `node_assets` row after uploading a file to Storage.
  Future<NodeAsset> createNodeAsset({
    required String nodeId,
    required String storagePath,
    required String mimeType,
    int? fileSizeBytes,
    int sortOrder = 0,
  }) =>
      guard(() async {
        final row = await supabase
            .from('node_assets')
            .insert({
              'node_id': nodeId,
              'storage_path': storagePath,
              'mime_type': mimeType,
              'file_size_bytes': fileSizeBytes,
              'sort_order': sortOrder,
            })
            .select()
            .single();
        return NodeAsset.fromJson(row);
      });

  /// Upload bytes to a private Supabase Storage bucket.
  Future<String> uploadToStorage({
    required String storageBucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await supabase.client.storage.from(storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  /// Delete a node_asset row and, when the storage location is known, its
  /// underlying Storage object too (delete-both, avoids orphaned files). The
  /// bucket is inferred from the mime type (pdf → `node-pdfs`, else images).
  Future<void> deleteNodeAsset(
    String assetId, {
    String? storagePath,
    String? mimeType,
  }) =>
      guard(() async {
        await supabase.from('node_assets').delete().eq('id', assetId);
        if (storagePath != null && storagePath.isNotEmpty) {
          final bucket =
              (mimeType ?? '').contains('pdf') ? 'node-pdfs' : 'node-images';
          try {
            await supabase.client.storage.from(bucket).remove([storagePath]);
          } catch (_) {
            // Row is gone; a failed storage cleanup shouldn't block the edit.
          }
        }
      });

  /// SHA-256 hex digest for content_hash (triggers embed pipeline on change).
  static String computeContentHash(String text) {
    final bytes = utf8.encode(text);
    return sha256.convert(bytes).toString();
  }
}
