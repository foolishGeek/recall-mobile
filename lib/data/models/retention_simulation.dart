// Recall · RetentionSimulation — the `retention-simulate` EF payload (premium).
// Powers the Insights retention hero + 90-day forgetting curve and the You-tab
// memory simulation (S22). All numbers are server-authoritative; the client
// only renders + animates. Hero percents are 0..100; curve points are 0..1.

import 'json_utils.dart';

/// One sampled day on the dual-line forgetting curve (0..1 retention).
class CurvePoint {
  final int day;
  final double withRecall;
  final double baseline;

  const CurvePoint({
    required this.day,
    required this.withRecall,
    required this.baseline,
  });

  factory CurvePoint.fromJson(Map<String, dynamic> json) => CurvePoint(
        day: asInt(json['day']),
        withRecall: asDouble(json['with_recall']),
        baseline: asDouble(json['baseline']),
      );
}

class RetentionSimulation {
  /// "With Recall" headline retention at day 90 (0..100).
  final double withRecallPct;

  /// "Without Recall" (baseline decay) retention at day 90 (0..100).
  final double baselinePct;

  /// 91 samples (day 0..90), solid `withRecall` / dashed `baseline`.
  final List<CurvePoint> curvePoints;

  /// True when `< 7` days of review history — numbers are a projection.
  final bool isProjected;

  /// Distinct days the user has reviewed (drives the projected caption / gate).
  final int reviewDaysCount;

  /// Loss-aversion anchor: nodes the spaced-repetition advantage is protecting.
  final int memoriesSaved;

  const RetentionSimulation({
    this.withRecallPct = 0,
    this.baselinePct = 0,
    this.curvePoints = const [],
    this.isProjected = true,
    this.reviewDaysCount = 0,
    this.memoriesSaved = 0,
  });

  factory RetentionSimulation.fromJson(Map<String, dynamic> json) =>
      RetentionSimulation(
        withRecallPct: asDouble(json['retention_with_recall']),
        baselinePct: asDouble(json['retention_baseline']),
        curvePoints: (json['curve_points'] is List)
            ? (json['curve_points'] as List)
                .whereType<Map>()
                .map((e) => CurvePoint.fromJson(
                      e.map((k, v) => MapEntry(k.toString(), v)),
                    ))
                .toList(growable: false)
            : const [],
        isProjected: asBool(json['is_projected'], true),
        reviewDaysCount: asInt(json['review_days_count']),
        memoriesSaved: asInt(json['memories_saved']),
      );

  bool get hasCurve => curvePoints.length > 1;
}
