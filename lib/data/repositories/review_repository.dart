// Recall · ReviewRepository. Append-only review log [D-OFF-1]. Insert is
// idempotent on `idempotency_key` (replay-safe); the 00003 trigger derives
// streak/XP/daily_activity/achievements server-side. Returns models only.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class ReviewRepository extends BaseRepository {
  ReviewRepository(SupabaseService supabase) : super(supabase, 'review');

  /// Appends a review. Upsert with `ignoreDuplicates` makes offline replay safe:
  /// a re-sent `idempotency_key` is a no-op rather than a conflict error.
  Future<void> append(Review review) => guard(() async {
        final payload = writable(review.toJson(), drop: {'id', 'created_at'});
        await supabase.from('reviews').upsert(
              payload,
              onConflict: 'idempotency_key',
              ignoreDuplicates: true,
            );
      });

  Future<List<Review>> fetchRecent(String userId, {int limit = 50}) =>
      guard(() async {
        final rows = await supabase
            .from('reviews')
            .select()
            .eq('user_id', userId)
            .order('reviewed_at', ascending: false)
            .limit(limit);
        return mapList(rows, Review.fromJson);
      });

  Future<List<Review>> fetchForNode(String nodeId) => guard(() async {
        final rows = await supabase
            .from('reviews')
            .select()
            .eq('node_id', nodeId)
            .order('reviewed_at', ascending: false);
        return mapList(rows, Review.fromJson);
      });
}
