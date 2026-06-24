// Recall · BucketRepository. Active-bucket scope via the tier-aware RPC, bucket
// CRUD (soft-delete), and the mastery/heat views. Returns models / typed records
// only. The free-tier bucket limit is enforced by a DB trigger → RepoException
// `free_tier_bucket_limit`.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

/// Fresh per-bucket heat stats from `v_bucket_heat`.
typedef BucketHeatStats = ({
  int nodeCount,
  int dueCount,
  int dominantPriority,
});

class BucketRepository extends BaseRepository {
  BucketRepository(SupabaseService supabase) : super(supabase, 'buckets');

  /// Tier-aware active buckets (premium: all · free: all owned · downgraded:
  /// first 3 by created_at) via `active_buckets_for_user`.
  Future<List<Bucket>> fetchActiveBuckets(String userId) => guard(() async {
        final res = await supabase.rpc(
          'active_buckets_for_user',
          params: {'uid': userId},
        );
        return mapList((res as List?) ?? const [], Bucket.fromJson);
      });

  /// All non-deleted buckets for the user, oldest first.
  Future<List<Bucket>> fetchAll(String userId) => guard(() async {
        final rows = await supabase
            .from('buckets')
            .select()
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: true);
        return mapList(rows, Bucket.fromJson);
      });

  Future<Bucket?> fetchById(String id) => guard(() async {
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
        return Bucket.fromJson(row);
      });

  Future<Bucket> update(String id, Map<String, dynamic> changes) =>
      guard(() async {
        final row = await supabase
            .from('buckets')
            .update(changes)
            .eq('id', id)
            .select()
            .single();
        return Bucket.fromJson(row);
      });

  Future<void> softDelete(String id) => guard(() async {
        await supabase.from('buckets').update(
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
        ).eq('id', id);
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
}
