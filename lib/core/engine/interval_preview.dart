// Recall · previewDueInterval — rating-button captions [D-ENG-4].

import '../../../data/models/enums.dart';
import '../../../data/models/node.dart';
import 'params/engine_config.dart';
import 'params/scheduling_params.dart';
import 'result/interval_preview.dart';
import 'fsrs.dart';
import 'record_review.dart';

String formatIntervalLabel(double intervalDays) {
  if (intervalDays < 1) return 'today';
  if (intervalDays < 7) return '+${intervalDays.round()}d';
  final weeks = (intervalDays / 7).round();
  return '+${weeks}w';
}

GradeInterval previewForGrade(
  Node n,
  ReviewGrade grade,
  DateTime now, {
  SchedulingParams params = SchedulingParams.defaults,
  EngineConfig config = EngineConfig.defaults,
  String timezone = 'UTC',
}) {
  final update = recordReview(
    n,
    grade,
    responseMs: 0,
    at: now,
    params: params,
    config: config,
    timezone: timezone,
  );
  final s = update.stabilityAfter ?? 0;
  final days = intervalDays(s, params);
  return GradeInterval(label: formatIntervalLabel(days), intervalDays: days);
}

IntervalPreview previewDueInterval(
  Node n, {
  DateTime? now,
  SchedulingParams params = SchedulingParams.defaults,
  EngineConfig config = EngineConfig.defaults,
  String timezone = 'UTC',
}) {
  final at = (now ?? DateTime.now()).toUtc();
  return IntervalPreview(
    again: previewForGrade(
      n,
      ReviewGrade.again,
      at,
      params: params,
      config: config,
      timezone: timezone,
    ),
    hard: previewForGrade(
      n,
      ReviewGrade.hard,
      at,
      params: params,
      config: config,
      timezone: timezone,
    ),
    good: previewForGrade(
      n,
      ReviewGrade.good,
      at,
      params: params,
      config: config,
      timezone: timezone,
    ),
    easy: previewForGrade(
      n,
      ReviewGrade.easy,
      at,
      params: params,
      config: config,
      timezone: timezone,
    ),
  );
}
