// Recall · NodeRepository. Node CRUD (soft-delete) plus assets and tags reads.
// Scheduling fields are written here by the engine (S04). Returns models only.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class NodeRepository extends BaseRepository {
  NodeRepository(SupabaseService supabase) : super(supabase, 'nodes');

  Future<List<Node>> fetchByBucket(String bucketId) => guard(() async {
        final rows = await supabase
            .from('nodes')
            .select()
            .eq('bucket_id', bucketId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);
        return mapList(rows, Node.fromJson);
      });

  Future<Node?> fetchById(String id) => guard(() async {
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
        return Node.fromJson(row);
      });

  /// Patches arbitrary node columns (content edits or engine scheduling fields).
  Future<Node> update(String id, Map<String, dynamic> changes) =>
      guard(() async {
        final row = await supabase
            .from('nodes')
            .update(changes)
            .eq('id', id)
            .select()
            .single();
        return Node.fromJson(row);
      });

  Future<void> softDelete(String id) => guard(() async {
        await supabase.from('nodes').update(
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
        ).eq('id', id);
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
