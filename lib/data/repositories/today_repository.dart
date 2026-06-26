import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

typedef TodaySummary = ({
  int dueCount,
  double aggregateHeat,
  int hotCount,
  int warmCount,
  int coolCount,
});

class TodayRepository extends BaseRepository {
  TodayRepository(SupabaseService supabase) : super(supabase, 'today');

  Future<TodaySummary> fetchTodaySummary() => guard(() async {
        final result = await supabase.rpc('today_summary_rpc');
        final json = asJsonMap(result);
        return (
          dueCount: asInt(json['due_count']),
          aggregateHeat: asDouble(json['aggregate_heat']),
          hotCount: asInt(json['hot_count']),
          warmCount: asInt(json['warm_count']),
          coolCount: asInt(json['cool_count']),
        );
      });

  Future<List<DuePreviewNode>> fetchDuePoolPreview({int limit = 3}) =>
      guard(() async {
        final result = await supabase.rpc(
          'due_pool_preview_rpc',
          params: {'p_limit': limit},
        );
        if (result is List) {
          return mapList(result, DuePreviewNode.fromJson);
        }
        return const [];
      });

  /// Cards eligible for review-ahead (`generate_stack_rpc(ahead=true)` pool).
  Future<int> fetchReviewAheadCount() => guard(() async {
        final result = await supabase.rpc('review_ahead_count_rpc');
        return asInt(result);
      });
}
