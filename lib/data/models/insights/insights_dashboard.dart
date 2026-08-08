// Recall · InsightsDashboard — payload from `insights_dashboard_rpc`.

import '../notification/notification_stats.dart';
import '../shared/json_utils.dart';
import 'daily_activity.dart';
import 'retention_simulation.dart';

/// One mastery ring as returned by the dashboard RPC (already capped/sorted).
typedef DashboardMasteryRing = ({String label, double progress, double heat});

/// `v_insights_summary` row (same shape as InsightsRepository typedef).
typedef DashboardSummary = ({
  int currentStreak,
  double? adherence7d,
  int daysWithReviews,
  int dueToday,
  int overdue,
});

/// `v_profile_lifetime` teaser fields.
typedef DashboardLifetime = ({
  int totalReviews,
  int totalNodes,
  double? lifetimeAdherencePct,
  DateTime? memberSince,
});

/// `v_weak_topics` row.
typedef DashboardWeakTopic = ({
  String nodeId,
  String title,
  String bucketId,
  String bucketName,
  int comfort,
  int priority,
  int difficulty,
});

class InsightsDashboard {
  final DashboardSummary? summary;
  final List<DailyActivity> dailyActivity;
  final bool simulationAllowed;
  final DashboardLifetime? lifetime;
  final double? teaserWithRecall;
  final double? teaserBaseline;
  final RetentionSimulation? retention;
  final bool retentionStale;
  final bool retentionPending;
  final List<DashboardMasteryRing> masteryRings;
  final int bucketCount;
  final List<DashboardWeakTopic> weakTopics;
  final List<DailyActivity> velocity;
  final NotificationStats? notificationStats;
  final List<NotificationDaily> notificationDaily;
  final Set<String> sectionErrors;

  const InsightsDashboard({
    this.summary,
    this.dailyActivity = const [],
    this.simulationAllowed = false,
    this.lifetime,
    this.teaserWithRecall,
    this.teaserBaseline,
    this.retention,
    this.retentionStale = false,
    this.retentionPending = false,
    this.masteryRings = const [],
    this.bucketCount = 0,
    this.weakTopics = const [],
    this.velocity = const [],
    this.notificationStats,
    this.notificationDaily = const [],
    this.sectionErrors = const {},
  });

  factory InsightsDashboard.fromJson(Map<String, dynamic> json) {
    final errorsRaw = json['errors'];
    final errors = <String>{};
    if (errorsRaw is Map) {
      for (final e in errorsRaw.entries) {
        if (e.value == true) errors.add(e.key.toString());
      }
    }

    final summaryRaw = json['summary'];
    final lifetimeRaw = json['lifetime'];
    final teaserRaw = json['teaser'];
    final retentionRaw = json['retention'];
    final notifRaw = json['notification_stats'];

    return InsightsDashboard(
      summary: summaryRaw is Map
          ? () {
              final summaryMap = asJsonMap(summaryRaw);
              return (
                currentStreak: asInt(summaryMap['current_streak']),
                adherence7d: asDoubleOrNull(summaryMap['adherence_7d']),
                daysWithReviews: asInt(summaryMap['days_with_reviews']),
                dueToday: asInt(summaryMap['due_today']),
                overdue: asInt(summaryMap['overdue']),
              );
            }()
          : null,
      dailyActivity: _activityList(json['daily_activity']),
      simulationAllowed: asBool(json['simulation_allowed']),
      lifetime: lifetimeRaw is Map
          ? () {
              final lifetimeMap = asJsonMap(lifetimeRaw);
              return (
                totalReviews: asInt(lifetimeMap['total_reviews']),
                totalNodes: asInt(lifetimeMap['total_nodes']),
                lifetimeAdherencePct:
                    asDoubleOrNull(lifetimeMap['lifetime_adherence_pct']),
                memberSince: asDateTime(lifetimeMap['member_since']),
              );
            }()
          : null,
      teaserWithRecall: teaserRaw is Map
          ? asDoubleOrNull(asJsonMap(teaserRaw)['retention_with_recall'])
          : null,
      teaserBaseline: teaserRaw is Map
          ? asDoubleOrNull(asJsonMap(teaserRaw)['retention_baseline'])
          : null,
      retention: retentionRaw is Map
          ? RetentionSimulation.fromJson(asJsonMap(retentionRaw))
          : null,
      retentionStale: asBool(json['retention_stale']),
      retentionPending: asBool(json['retention_pending']),
      masteryRings: _masteryList(json['mastery_rings']),
      bucketCount: asInt(json['bucket_count']),
      weakTopics: _weakList(json['weak_topics']),
      velocity: _activityList(json['velocity']),
      notificationStats: notifRaw is Map
          ? NotificationStats.fromJson(asJsonMap(notifRaw))
          : null,
      notificationDaily: _notifDailyList(json['notification_daily']),
      sectionErrors: errors,
    );
  }

  static List<DailyActivity> _activityList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DailyActivity.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .toList(growable: false);
  }

  static List<DashboardMasteryRing> _masteryList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) {
      final m = e.map((k, v) => MapEntry(k.toString(), v));
      return (
        label: asString(m['label']),
        progress: asDouble(m['progress']),
        heat: asDouble(m['heat']),
      );
    }).toList(growable: false);
  }

  static List<DashboardWeakTopic> _weakList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) {
      final m = e.map((k, v) => MapEntry(k.toString(), v));
      return (
        nodeId: asString(m['node_id']),
        title: asString(m['title']),
        bucketId: asString(m['bucket_id']),
        bucketName: asString(m['bucket_name']),
        comfort: asInt(m['comfort']),
        priority: asInt(m['priority']),
        difficulty: asInt(m['difficulty']),
      );
    }).toList(growable: false);
  }

  static List<NotificationDaily> _notifDailyList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => NotificationDaily.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .toList(growable: false);
  }
}
