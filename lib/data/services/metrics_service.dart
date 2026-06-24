// Recall · MetricsService — read/orchestration after persistence [S04 §4c].
// Streak/XP/level/daily_activity/achievements are server-authoritative (00003);
// this layer re-reads profile/views and surfaces deltas for celebratory UI.

import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/engine/gamification.dart';
import '../models/models.dart';
import '../repositories/insights_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/review_repository.dart';
import 'metrics_snapshot.dart';

class MetricsService extends GetxService {
  MetricsService(
    this._profiles,
    this._insights,
    this._reviews,
  );

  final ProfileRepository _profiles;
  final InsightsRepository _insights;
  final ReviewRepository _reviews;

  /// Called after a review row is persisted. Re-reads server-computed profile
  /// and adherence; never throws to callers.
  Future<ReviewMetricsSnapshot?> onReviewRecorded(
    Review review,
    Profile profileBefore,
  ) async {
    try {
      final profileAfter =
          await _profiles.fetchProfile(review.userId) ?? profileBefore;
      final summary = await _insights.fetchSummary(review.userId);

      return ReviewMetricsSnapshot(
        profile: profileAfter,
        xpDelta: profileAfter.xp - profileBefore.xp,
        streakDelta: profileAfter.currentStreak - profileBefore.currentStreak,
        levelIncreased: profileAfter.level > profileBefore.level,
        adherence7d: summary?.adherence7d,
      );
    } catch (e, st) {
      await _captureNonFatal(e, st, 'onReviewRecorded');
      return null;
    }
  }

  /// Called when a stack is created. Refreshes monthly usage for the meter.
  Future<StackUsageSnapshot?> onStackStarted(
    Stack stack,
    Profile profile,
  ) async {
    try {
      final stacksCreated =
          await _profiles.fetchStacksCreatedThisMonth(profile.id);
      return StackUsageSnapshot(stacksCreatedThisMonth: stacksCreated);
    } catch (e, st) {
      await _captureNonFatal(e, st, 'onStackStarted');
      return null;
    }
  }

  /// Called when a stack completes. Re-reads profile + optional duration hint.
  Future<StackCompletedSnapshot?> onStackCompleted(
    Stack stack,
    Profile profileBefore,
  ) async {
    try {
      final profileAfter =
          await _profiles.fetchProfile(stack.userId) ?? profileBefore;
      final reviews = await _reviews.fetchRecent(stack.userId, limit: 200);
      final stackReviews = reviews
          .where((r) => r.stackId == stack.id && r.reviewedAt != null)
          .toList();

      int? durationMinutes;
      var fasterThanUsual = false;
      if (stackReviews.length >= 2) {
        final times = stackReviews.map((r) => r.reviewedAt!).toList()
          ..sort();
        final span = times.last.difference(times.first);
        durationMinutes = span.inMinutes.clamp(1, 9999);
        fasterThanUsual = durationMinutes <= 5;
      }

      return StackCompletedSnapshot(
        profile: profileAfter,
        durationMinutes: durationMinutes,
        fasterThanUsual: fasterThanUsual,
      );
    } catch (e, st) {
      await _captureNonFatal(e, st, 'onStackCompleted');
      return null;
    }
  }

  int levelForProfile(Profile profile) => levelForXp(profile.xp);

  double progressForProfile(Profile profile) => levelProgress(profile.xp);

  Future<void> _captureNonFatal(
    Object e,
    StackTrace st,
    String hook,
  ) async {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'MetricsService.$hook failed (non-fatal)',
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
