// Recall · MetricsService. Backend triggers/views are source-of-truth for
// streak, XP/level, adherence, daily_activity, achievements, and usage.
// This layer refreshes server rows only; it does not compute product metrics.

import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/models.dart';
import '../repositories/insights_repository.dart';
import '../repositories/profile_repository.dart';

class MetricsService extends GetxService {
  MetricsService(this._profiles, this._insights);

  final ProfileRepository _profiles;
  final InsightsRepository _insights;

  Future<void> onReviewRecorded(Review review, Profile profile) async {
    await _nonFatal('onReviewRecorded', () async {
      await _profiles.fetchProfile(review.userId);
      await _insights.fetchSummary(review.userId);
    });
  }

  Future<void> onStackStarted(Stack stack, Profile profile) async {
    await _nonFatal('onStackStarted', () async {
      await _profiles.fetchStacksCreatedThisMonth(profile.id);
    });
  }

  Future<void> onStackCompleted(Stack stack, Profile profile) async {
    await _nonFatal('onStackCompleted', () async {
      await _profiles.fetchProfile(stack.userId);
      await _insights.fetchSummary(stack.userId);
    });
  }

  Future<void> _nonFatal(
    String hook,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e, st) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'MetricsService.$hook refresh failed (non-fatal)',
          category: 'metrics',
          level: SentryLevel.warning,
        ),
      );
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'metrics'),
      );
    }
  }
}
