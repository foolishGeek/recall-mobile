// Recall · recordReview — deterministic FSRS state transition [D-ENG-7].

import '../../../data/models/enums.dart';
import '../../../data/models/node.dart';
import 'params/engine_config.dart';
import 'params/scheduling_params.dart';
import 'result/engine_update.dart';
import 'utils/timezone_utils.dart';
import 'fsrs.dart';

EngineUpdate recordReview(
  Node n,
  ReviewGrade g, {
  required int responseMs,
  DateTime? at,
  SchedulingParams params = SchedulingParams.defaults,
  EngineConfig config = EngineConfig.defaults,
  String timezone = 'UTC',
}) {
  if (responseMs < 0) {
    throw ArgumentError.value(responseMs, 'responseMs', 'must be >= 0');
  }

  final reviewedAt = (at ?? DateTime.now()).toUtc();
  final rBefore = retrievability(n, reviewedAt, params: params);
  final dueBefore = n.dueAt;
  final sBefore = n.stability;
  final dBefore = n.difficulty;
  final comfortBefore = n.comfort;

  var state = n.state;
  var stability = n.stability;
  var difficulty = n.difficulty;
  var reps = n.reps;
  var lapses = n.lapses;
  DateTime? dueAt;

  final sameDay = n.lastReviewedAt != null &&
      sameLocalDay(n.lastReviewedAt!, reviewedAt, timezone);
  final freezeStability = sameDay && !isFirstReview(n);

  if (isFirstReview(n)) {
    stability = s0(g, difficulty);
    if (isSuccessGrade(g)) {
      state = NodeState.review;
      dueAt = dueFromLastReview(reviewedAt, stability, params);
    } else {
      state = NodeState.learning;
      dueAt = reviewedAt.add(Duration(minutes: config.learningStepMinutes));
    }
    if (g == ReviewGrade.again) lapses += 1;
  } else if (g == ReviewGrade.again) {
    lapses += 1;
    if (state == NodeState.review) {
      state = NodeState.relearning;
      if (!freezeStability) {
        stability = lapseStability(
          stability ?? params.sMin,
          difficulty,
          rBefore,
          params,
        );
      }
      dueAt = reviewedAt.add(Duration(minutes: config.learningStepMinutes));
    } else {
      state = NodeState.learning;
      if (!freezeStability) {
        stability = s0(g, difficulty);
      }
      dueAt = reviewedAt.add(Duration(minutes: config.learningStepMinutes));
    }
  } else {
    final currentS = stability ?? params.sMin;
    if (state == NodeState.learning || state == NodeState.relearning) {
      state = NodeState.review;
      if (!freezeStability) {
        stability = successStability(
          currentS,
          difficulty,
          g,
          rBefore,
          params,
        );
      }
    } else if (!freezeStability) {
      stability = successStability(
        currentS,
        difficulty,
        g,
        rBefore,
        params,
      );
    }
    dueAt = dueFromLastReview(
      reviewedAt,
      stability ?? currentS,
      params,
    );
  }

  if (!freezeStability) {
    difficulty = driftDifficulty(difficulty, g, params);
  }

  if (lapses >= params.leechLapseThreshold) {
    state = NodeState.leech;
  }

  reps += 1;
  final comfortAfter =
      comfortFromStability(stability ?? 0, params.comfortK);

  final updated = n.copyWith(
    stability: stability,
    difficulty: difficulty,
    comfort: comfortAfter,
    lastReviewedAt: reviewedAt,
    dueAt: dueAt,
    reps: reps,
    lapses: lapses,
    state: state,
    lastGrade: g,
    lastResponseMs: responseMs,
  );

  final rAfter = retrievability(updated, reviewedAt, params: params);

  return EngineUpdate(
    node: updated,
    stabilityBefore: sBefore,
    stabilityAfter: stability,
    difficultyBefore: dBefore,
    difficultyAfter: difficulty,
    comfortBefore: comfortBefore,
    comfortAfter: comfortAfter,
    retrievabilityBefore: rBefore,
    retrievabilityAfter: rAfter,
    dueBefore: dueBefore,
    dueAfter: dueAt,
  );
}
