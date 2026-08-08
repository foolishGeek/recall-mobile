// Recall · InsightsRepository. Read-only over the analytics views + activity /
// achievements tables (all written server-side). Dashboard bootstrap collapses
// Insights into one RPC; retention uses the shared resolve cache.

import 'package:flutter/foundation.dart';

import '../../../core/utils/load_cache_ttl.dart';
import '../../models/models.dart';
import '../../services/platform/supabase_service.dart';
import '../../services/shared/repo_exception.dart';
import '../base/base_repository.dart';

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

  InsightsDashboard? _memoryDashboard;
  DateTime? _memoryAt;

  /// RAM Cache 2 — last successful dashboard (TTL [kInsightsMemoryTtl]).
  InsightsDashboard? get memoryDashboard {
    final cached = _memoryDashboard;
    final at = _memoryAt;
    if (cached == null || at == null) return null;
    if (DateTime.now().difference(at) > kInsightsMemoryTtl) return null;
    return cached;
  }

  bool get hasFreshMemoryDashboard => memoryDashboard != null;

  void clearMemoryCache() {
    _memoryDashboard = null;
    _memoryAt = null;
  }

  void _storeMemory(InsightsDashboard dashboard) {
    _memoryDashboard = dashboard;
    _memoryAt = DateTime.now();
  }

  /// Single Insights bootstrap (`insights_dashboard_rpc`).
  Future<InsightsDashboard> fetchDashboard({
    bool forceRetention = false,
    bool bypassMemory = false,
  }) =>
      guard(() async {
        if (!bypassMemory) {
          final mem = memoryDashboard;
          if (mem != null) return mem;
        }

        final sw = kDebugMode ? (Stopwatch()..start()) : null;
        final result = await supabase.rpc(
          'insights_dashboard_rpc',
          params: {'p_force_retention': forceRetention},
        );
        final dashboard = InsightsDashboard.fromJson(asJsonMap(result));
        _storeMemory(dashboard);
        if (sw != null) {
          debugPrint(
            '[perf] insights_dashboard_rpc ${sw.elapsedMilliseconds}ms '
            '(sim=${dashboard.simulationAllowed})',
          );
        }
        return dashboard;
      });

  /// Warm Cache 2 after Today settles (best-effort).
  Future<void> prefetchDashboard() async {
    try {
      await fetchDashboard();
    } catch (_) {/* warm path — ignore */}
  }

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

  /// 30-day Drop send/open totals (`v_notification_stats`). The view groups by
  /// user; RLS (security_invoker) already scopes to the caller.
  Future<NotificationStats?> fetchNotificationStats(String userId) =>
      guard(() async {
        final row = await supabase
            .from('v_notification_stats')
            .select('sent_30d, opened_30d')
            .eq('user_id', userId)
            .maybeSingle();
        return row == null ? null : NotificationStats.fromJson(row);
      });

  /// Recent per-day Drop sent/opened counts (`v_notification_daily`) for the
  /// mini bar chart. Newest [limit] days, returned oldest-first for plotting.
  Future<List<NotificationDaily>> fetchNotificationDaily(
    String userId, {
    int limit = 7,
  }) =>
      guard(() async {
        final rows = await supabase
            .from('v_notification_daily')
            .select('day, sent, opened')
            .eq('user_id', userId)
            .order('day', ascending: false)
            .limit(limit);
        final list = mapList(rows, NotificationDaily.fromJson);
        return list.reversed.toList(growable: false);
      });

  /// Shared retention path (Insights + You).
  /// - [force] false: cache-only RPC (never runs the heavy simulate).
  /// - [force] true: Edge Function `retention-simulate` (longer timeout, background).
  Future<RetentionSimulation?> resolveRetention({bool force = false}) =>
      guard(() async {
        final sw = kDebugMode ? (Stopwatch()..start()) : null;
        if (force) {
          final data = await supabase.invokeFunction('retention-simulate');
          if (sw != null) {
            debugPrint(
              '[perf] retention-simulate EF ${sw.elapsedMilliseconds}ms',
            );
          }
          return RetentionSimulation.fromJson(asJsonMap(data));
        }

        final data = await supabase.rpc(
          'retention_resolve_rpc',
          params: {'p_force': false},
        );
        if (sw != null) {
          debugPrint(
            '[perf] retention_resolve_rpc ${sw.elapsedMilliseconds}ms',
          );
        }
        if (data == null) return null;
        return RetentionSimulation.fromJson(asJsonMap(data));
      });

  /// Backward-compatible name used by You / Insights — never forces simulate.
  Future<RetentionSimulation> simulateRetention({bool force = false}) async {
    final r = await resolveRetention(force: force);
    if (r == null) {
      throw RepoException(
        RepoErrorCode.notFound,
        'No retention curve cached yet.',
      );
    }
    return r;
  }

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
