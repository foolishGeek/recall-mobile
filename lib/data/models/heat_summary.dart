// Recall · HeatSummary — typed view of buckets.heat_summary jsonb [02c].
// Defaults safely when the key is absent or `{}` so parsing never crashes.

import 'json_utils.dart';

class HeatSummary {
  final double aggregateHeat;
  final double masteryProgress;
  final int hotCount;
  final int warmCount;
  final int coolCount;
  final List<double> segments;
  final int dominantPriority;

  const HeatSummary({
    this.aggregateHeat = 0,
    this.masteryProgress = 0,
    this.hotCount = 0,
    this.warmCount = 0,
    this.coolCount = 0,
    this.segments = const [],
    this.dominantPriority = 1,
  });

  static const empty = HeatSummary();

  factory HeatSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['segments'];
    return HeatSummary(
      aggregateHeat: asDouble(json['aggregate_heat']),
      masteryProgress: asDouble(json['mastery_progress']),
      hotCount: asInt(json['hot_count']),
      warmCount: asInt(json['warm_count']),
      coolCount: asInt(json['cool_count']),
      segments:
          raw is List ? raw.map((e) => asDouble(e)).toList() : const [],
      dominantPriority: asInt(json['dominant_priority'], 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'aggregate_heat': aggregateHeat,
        'mastery_progress': masteryProgress,
        'hot_count': hotCount,
        'warm_count': warmCount,
        'cool_count': coolCount,
        'segments': segments,
        'dominant_priority': dominantPriority,
      };

  HeatSummary copyWith({
    double? aggregateHeat,
    double? masteryProgress,
    int? hotCount,
    int? warmCount,
    int? coolCount,
    List<double>? segments,
    int? dominantPriority,
  }) {
    return HeatSummary(
      aggregateHeat: aggregateHeat ?? this.aggregateHeat,
      masteryProgress: masteryProgress ?? this.masteryProgress,
      hotCount: hotCount ?? this.hotCount,
      warmCount: warmCount ?? this.warmCount,
      coolCount: coolCount ?? this.coolCount,
      segments: segments ?? this.segments,
      dominantPriority: dominantPriority ?? this.dominantPriority,
    );
  }
}
