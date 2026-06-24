// Recall · ReviewRepository. Append-only review log [D-OFF-1]. The backend
// `record_review_rpc` is the only writer for reviews + node scheduling state.
// Mobile sends intent only; server returns the persisted review and node.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

typedef ReviewRecordResult = ({Review review, Node node, bool duplicate});

class ReviewRepository extends BaseRepository {
  ReviewRepository(SupabaseService supabase) : super(supabase, 'review');

  /// Records a review through the backend-authoritative engine RPC. The RPC is
  /// idempotent on `idempotency_key` and writes node scheduling fields.
  Future<ReviewRecordResult> append(Review review) => guard(() async {
        final result = await supabase.rpc(
          'record_review_rpc',
          params: {
            'payload': writable(review.toJson(), drop: {'id', 'created_at'})
          },
        );
        final map = asJsonMap(result);
        return (
          review: Review.fromJson(asJsonMap(map['review'])),
          node: Node.fromJson(asJsonMap(map['node'])),
          duplicate: asBool(map['duplicate']),
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
