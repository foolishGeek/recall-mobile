// Recall · FSRS core math — retrievability, stability updates, comfort [S04 §4].

import 'dart:math' as math;

import '../../../data/models/enums.dart';
import '../../../data/models/node.dart';
import 'params/scheduling_params.dart';

int gradeValue(ReviewGrade g) => switch (g) {
      ReviewGrade.again => 1,
      ReviewGrade.hard => 2,
      ReviewGrade.good => 3,
      ReviewGrade.easy => 4,
    };

double daysBetween(DateTime from, DateTime to) =>
    to.difference(from).inMicroseconds / Duration.microsecondsPerDay;

double clamp01(double v) => v.clamp(0.0, 1.0);

int clampDifficulty(int d) => d.clamp(1, 5);

double intervalDays(double stability, SchedulingParams params) =>
    9 * stability * (1 / params.targetRetention - 1);

DateTime dueFromLastReview(
  DateTime lastReviewedAt,
  double stability,
  SchedulingParams params,
) =>
    lastReviewedAt.add(
      Duration(
        microseconds:
            (intervalDays(stability, params) * Duration.microsecondsPerDay)
                .round(),
      ),
    );

/// R(t) = (1 + t/(9·S))^(-1); S=null → R=0.
double retrievability(
  Node n,
  DateTime at, {
  SchedulingParams params = SchedulingParams.defaults,
}) {
  final s = n.stability;
  final last = n.lastReviewedAt;
  if (s == null || last == null || s <= 0) return 0;
  final t = daysBetween(last.toUtc(), at.toUtc());
  if (t < 0) return 1;
  return math.pow(1 + t / (9 * s), -1).toDouble();
}

/// First-review S0 seeds × (1 − 0.05·(D−3)).
double s0(ReviewGrade grade, int difficulty) {
  final base = switch (grade) {
    ReviewGrade.again => 0.4,
    ReviewGrade.hard => 1.0,
    ReviewGrade.good => 3.0,
    ReviewGrade.easy => 8.0,
  };
  return base * (1 - 0.05 * (difficulty - 3));
}

/// comfort = round(100·S/(S+K)) [D-ENG-8].
int comfortFromStability(double stability, double comfortK) {
  if (stability <= 0) return 0;
  return (100 * stability / (stability + comfortK)).round();
}

/// Comfort seed for new nodes: S = comfort·K/(100−comfort).
double stabilityFromComfort(int comfort, double comfortK) {
  if (comfort >= 100) return comfortK * 10;
  if (comfort <= 0) return 0;
  return comfort * comfortK / (100 - comfort);
}

double penaltyForGrade(ReviewGrade grade, SchedulingParams params) =>
    switch (grade) {
      ReviewGrade.hard => params.hardPenalty,
      ReviewGrade.good => 1.0,
      ReviewGrade.easy => params.easyBonus,
      ReviewGrade.again => 1.0,
    };

/// Success path (g≥2): stability growth [D-ENG-1].
double successStability(
  double s,
  int difficulty,
  ReviewGrade grade,
  double r,
  SchedulingParams params,
) {
  final growth = math.exp(params.w1) *
      (6 - difficulty) *
      math.pow(s, -params.w2) *
      (math.exp(params.w3 * (1 - r)) - 1) *
      penaltyForGrade(grade, params);
  return s * (1 + growth);
}

/// Lapse path (again from review): stability drop §4.3.
double lapseStability(
  double s,
  int difficulty,
  double r,
  SchedulingParams params,
) {
  final next = params.w4 *
      math.pow(difficulty.toDouble(), -params.w5) *
      math.pow(s, params.w6) *
      math.exp(params.w7 * (1 - r));
  return math.max(params.sMin, next);
}

int driftDifficulty(int d, ReviewGrade grade, SchedulingParams params) {
  final g = gradeValue(grade);
  return clampDifficulty((d - params.w8 * (g - 3)).round());
}

bool isFirstReview(Node n) =>
    n.state == NodeState.newNode || n.stability == null;

bool isSuccessGrade(ReviewGrade grade) => gradeValue(grade) >= 2;
