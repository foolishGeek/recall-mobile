// Recall · HeatService — aggregates engine heat for bucket/today UI [S04 §4c].

import 'package:get/get.dart' hide Node;

import '../../core/engine/engine.dart';
import '../models/models.dart';
import '../repositories/config_repository.dart';

class HeatService extends GetxService {
  HeatService(this._config);

  final ConfigRepository _config;

  SchedulingParams _params = SchedulingParams.defaults;

  Future<void> warmCache() async {
    _params = await _config.fetchSchedulingParams();
  }

  /// Aggregates a [HeatSummary] across the user's due nodes for the today ring.
  HeatSummary summaryForUser(
    List<Node> due,
    int sessionSize, {
    SchedulingParams? params,
    DateTime? now,
  }) {
    final p = params ?? _params;
    final utcNow = (now ?? DateTime.now()).toUtc();
    if (due.isEmpty) return HeatSummary.empty;

    final heats = due.map((n) => heat(n, utcNow, params: p)).toList();
    final aggregate = heats.reduce((a, b) => a + b) / heats.length;

    final segments = List<double>.filled(10, 0);
    for (final h in heats) {
      final idx = (h * 10).floor().clamp(0, 9);
      segments[idx] += 1 / heats.length;
    }

    var hot = 0;
    var warm = 0;
    var cool = 0;
    for (final h in heats) {
      if (h >= 0.66) {
        hot += 1;
      } else if (h >= 0.33) {
        warm += 1;
      } else {
        cool += 1;
      }
    }

    final priorityCounts = <int, int>{};
    for (final n in due) {
      priorityCounts[n.priority] = (priorityCounts[n.priority] ?? 0) + 1;
    }
    var dominantPriority = 1;
    var maxCount = 0;
    priorityCounts.forEach((priority, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantPriority = priority;
      }
    });

    final masteryProgress = due
            .map((n) => n.comfort / 100.0)
            .fold<double>(0, (a, b) => a + b) /
        due.length;

    return HeatSummary(
      aggregateHeat: aggregate,
      masteryProgress: masteryProgress,
      hotCount: hot,
      warmCount: warm,
      coolCount: cool,
      segments: segments,
      dominantPriority: dominantPriority,
    );
  }

  /// Home heat ring visual params [11-metrics §10].
  HeatRing ringFor(int dueCount, int sessionSize) {
    final load = sessionSize <= 0 ? 0.0 : dueCount / sessionSize;
    return HeatRing.forLoad(load);
  }
}
