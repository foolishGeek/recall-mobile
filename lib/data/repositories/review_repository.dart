// Recall · ReviewRepository. Append-only review log [D-OFF-1]. Reviews are
// enqueued locally first (durable across app kills) and replayed in
// `client_timestamp` order through the backend-authoritative `record_review_rpc`
// by SyncService. When the cache is unavailable (DB open failed) it falls back
// to a direct online RPC. Mobile sends intent only; the server computes and
// returns the persisted review + node scheduling state.

import 'dart:async';

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'base_repository.dart';

/// `queued` = the review went to the offline queue (replays in the background);
/// `node` is then the cached node (server scheduling lands after replay). When
/// recorded directly online, `queued` is false and `node` is the server row.
typedef ReviewRecordResult = ({
  Review review,
  Node? node,
  bool duplicate,
  bool queued,
});

class ReviewRepository extends BaseRepository {
  ReviewRepository(SupabaseService supabase, this._local, this._sync)
      : super(supabase, 'review');

  final LocalStore _local;
  final SyncService _sync;

  /// Records a review. With the cache enabled this appends to the offline queue
  /// (append-only, deduped by idempotency key) and kicks a background drain,
  /// returning optimistically. Without the cache it records directly online.
  Future<ReviewRecordResult> append(Review review) async {
    if (!_local.isEnabled) return _recordDirect(review);

    await _local.enqueueReview(review);
    final cached = await _local.cachedNodeById(review.nodeId);
    unawaited(_sync.drain());
    return (review: review, node: cached, duplicate: false, queued: true);
  }

  Future<ReviewRecordResult> _recordDirect(Review review) => guard(() async {
        final result = await supabase.rpc(
          'record_review_rpc',
          params: {
            'payload': writable(review.toJson(), drop: {'id', 'created_at'}),
          },
        );
        final map = asJsonMap(result);
        return (
          review: Review.fromJson(asJsonMap(map['review'])),
          node: Node.fromJson(asJsonMap(map['node'])),
          duplicate: asBool(map['duplicate']),
          queued: false,
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

  Future<List<Review>> fetchForStack(String stackId) => guard(() async {
        final rows = await supabase
            .from('reviews')
            .select()
            .eq('stack_id', stackId)
            .order('reviewed_at', ascending: true);
        return mapList(rows, Review.fromJson);
      });
}
