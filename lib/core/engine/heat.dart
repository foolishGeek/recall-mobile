// Recall · heat() — urgency score for stack ranking [S04 §4].

import '../../../data/models/node.dart';
import 'params/scheduling_params.dart';
import 'fsrs.dart';

/// heat = clamp01((now−due)/max(I,1)+(1−R)) · (1+0.15·(P−1)) · (1+0.12·(D−3))
double heat(
  Node n,
  DateTime now, {
  SchedulingParams params = SchedulingParams.defaults,
}) {
  final s = n.stability ?? stabilityFromComfort(n.comfort, params.comfortK);
  final r = retrievability(n, now, params: params);
  final due = n.dueAt ?? now;
  final i = mathMax(intervalDays(s, params), 1.0);
  final overdue = daysBetween(due.toUtc(), now.toUtc());
  final base = clamp01(overdue / i + (1 - r));
  final priorityBoost = 1 + 0.15 * (n.priority - 1);
  final difficultyBoost = 1 + 0.12 * (n.difficulty - 3);
  return clamp01(base * priorityBoost * difficultyBoost);
}

double mathMax(double a, double b) => a > b ? a : b;
