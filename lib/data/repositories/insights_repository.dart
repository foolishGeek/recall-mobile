// Recall · InsightsRepository. Read-only over the analytics views + activity /
// achievements tables (all written server-side). Returns models / typed records.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

/// `v_insights_summary` row.
typedef InsightsSummary = ({
  int currentStreak,
  double? adherence7d,
  int daysWithReviews,
  int dueToday,
  int overdue,
});

/// `v_profile_lifetime` row.
typedef ProfileLifetime = ({
  int totalReviews,
  int totalNodes,
  double? lifetimeAdherencePct,
  DateTime? memberSince,
});

/// `v_weak_topics` row (+bucket_name).
typedef WeakTopic = ({
  String nodeId,
  String title,
  String bucketId,
  String bucketName,
  int comfort,
  int priority,
  int difficulty,
});

class InsightsRepository extends BaseRepository {
  InsightsRepository(SupabaseService supabase) : super(supabase, 'insights');

  Future<InsightsSummary?> fetchSummary(String userId) => guard(() async {
        final row = await supabase
            .from('v_insights_summary')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (row == null) return null;
        return (
          currentStreak: asInt(row['current_streak']),
          adherence7d: asDoubleOrNull(row['adherence_7d']),
          daysWithReviews: asInt(row['days_with_reviews']),
          dueToday: asInt(row['due_today']),
          overdue: asInt(row['overdue']),
        );
      });

  Future<ProfileLifetime?> fetchLifetime(String userId) => guard(() async {
        final row = await supabase
            .from('v_profile_lifetime')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (row == null) return null;
        return (
          totalReviews: asInt(row['total_reviews']),
          totalNodes: asInt(row['total_nodes']),
          lifetimeAdherencePct: asDoubleOrNull(row['lifetime_adherence_pct']),
          memberSince: asDateTime(row['member_since']),
        );
      });

  /// 84-day review counts (`v_daily_activity`) for the heatmap.
  Future<List<DailyActivity>> fetchDailyActivity(String userId) =>
      guard(() async {
        final rows = await supabase
            .from('v_daily_activity')
            .select()
            .eq('user_id', userId)
            .order('activity_date', ascending: true);
        return mapList(rows, DailyActivity.fromJson);
      });

  /// 14-day review velocity (`v_review_velocity_daily`).
  Future<List<DailyActivity>> fetchReviewVelocity(String userId) =>
      guard(() async {
        final rows = await supabase
            .from('v_review_velocity_daily')
            .select()
            .eq('user_id', userId)
            .order('activity_date', ascending: true);
        return mapList(rows, DailyActivity.fromJson);
      });

  /// Weak topics (`v_weak_topics`). The view has no user_id column; RLS
  /// (security_invoker) already scopes rows to the caller.
  Future<List<WeakTopic>> fetchWeakTopics() => guard(() async {
        final rows = await supabase.from('v_weak_topics').select();
        return rows
            .map<WeakTopic>((r) => (
                  nodeId: asString(r['node_id']),
                  title: asString(r['title']),
                  bucketId: asString(r['bucket_id']),
                  bucketName: asString(r['bucket_name']),
                  comfort: asInt(r['comfort']),
                  priority: asInt(r['priority']),
                  difficulty: asInt(r['difficulty']),
                ))
            .toList(growable: false);
      });

  Future<List<Achievement>> fetchAchievements() => guard(() async {
        final rows = await supabase.from('achievements').select();
        return mapList(rows, Achievement.fromJson);
      });

  Future<List<UserAchievement>> fetchUserAchievements(String userId) =>
      guard(() async {
        final rows = await supabase
            .from('user_achievements')
            .select()
            .eq('user_id', userId)
            .order('unlocked_at', ascending: false);
        return mapList(rows, UserAchievement.fromJson);
      });
}
