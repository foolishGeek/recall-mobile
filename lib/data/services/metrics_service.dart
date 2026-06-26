// Recall · MetricsService. Backend triggers/views are source-of-truth for
// streak, XP/level, adherence, daily_activity, achievements, and usage.
// This layer refreshes server rows only; it does not compute product metrics
// except [D-UI-3] done-fast banner (cosmetic, client-only presentation).

import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/models.dart';
import '../repositories/insights_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/stack_repository.dart';
import '../services/auth_service.dart';
import '../services/tier_service.dart';

typedef DoneFastBanner = ({int minutes, bool fasterThanUsual});

class MetricsService extends GetxService {
  MetricsService(
    this._profiles,
    this._insights,
    this._reviews,
    this._stacks,
  );

  final ProfileRepository _profiles;
  final InsightsRepository _insights;
  final ReviewRepository _reviews;
  final StackRepository _stacks;

  String? _lastCompletedStackId;
  DateTime? _lastCompletedAt;

  void markStackCompleted(String stackId) {
    _lastCompletedStackId = stackId;
    _lastCompletedAt = DateTime.now();
  }

  void clearDoneFastCache() {
    _lastCompletedStackId = null;
    _lastCompletedAt = null;
  }

  /// S26 §7 — breadcrumb when a downgraded user hits a gated surface.
  void downgradedGateHit(String screen, {Map<String, String>? params}) {
    if (!Get.isRegistered<AuthService>() || !Get.isRegistered<TierService>()) {
      return;
    }
    final auth = Get.find<AuthService>();
    if (!auth.analyticsOptIn) return;
    final tier = Get.find<TierService>();
    if (!tier.isDowngraded) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'analytics',
        message: 'downgraded_gate_hit',
        data: {'screen': screen, ...?params},
      ),
    );
  }

  /// Returns a done-fast banner when the last stack finished ≤5 min ago and
  /// trailing history exists; clears the one-shot cache after read.
  Future<DoneFastBanner?> consumeDoneFastBanner() async {
    final stackId = _lastCompletedStackId;
    final completedAt = _lastCompletedAt;
    if (stackId == null || completedAt == null) return null;

    if (DateTime.now().difference(completedAt) > const Duration(minutes: 5)) {
      clearDoneFastCache();
      return null;
    }

    try {
      final stackReviews = await _reviews.fetchForStack(stackId);
      if (stackReviews.isEmpty) {
        clearDoneFastCache();
        return null;
      }

      final userId = stackReviews.first.userId;
      final recentStacks =
          await _stacks.fetchRecentCompleted(userId, limit: 11);
      final trailingDurations = <int>[];
      for (final s in recentStacks.where((s) => s.id != stackId).take(10)) {
        final rs = await _reviews.fetchForStack(s.id);
        final mins = stackDurationMinutes(rs);
        if (mins != null && mins > 0) trailingDurations.add(mins);
      }

      final banner = computeDoneFastBanner(
        stackCompletedAt: completedAt,
        stackReviews: stackReviews,
        trailingStackDurationsMin: trailingDurations,
      );

      clearDoneFastCache();
      return banner;
    } catch (e, st) {
      Sentry.addBreadcrumb(Breadcrumb(
        category: 'metrics',
        message: 'consumeDoneFastBanner failed (non-fatal)',
        level: SentryLevel.warning,
      ));
      await Sentry.captureException(e, stackTrace: st);
      clearDoneFastCache();
      return null;
    }
  }

  /// [D-UI-3] Cosmetic banner math — only shown when trailing data exists.
  static DoneFastBanner? computeDoneFastBanner({
    required DateTime stackCompletedAt,
    required List<Review> stackReviews,
    required List<int> trailingStackDurationsMin,
  }) {
    if (DateTime.now().difference(stackCompletedAt) > const Duration(minutes: 5)) {
      return null;
    }

    final lastMin = stackDurationMinutes(stackReviews);
    if (lastMin == null || lastMin <= 0) return null;
    if (trailingStackDurationsMin.isEmpty) return null;

    final avg = trailingStackDurationsMin.reduce((a, b) => a + b) /
        trailingStackDurationsMin.length;
    final faster = lastMin < avg;

    if (!faster) return null;

    return (minutes: lastMin, fasterThanUsual: true);
  }

  /// Duration of a stack session in whole minutes.
  static int? stackDurationMinutes(List<Review> reviews) {
    if (reviews.isEmpty) return null;

    final times = reviews
        .map((r) => r.reviewedAt)
        .whereType<DateTime>()
        .toList();
    if (times.length >= 2) {
      times.sort();
      final span = times.last.difference(times.first);
      final mins = span.inMinutes;
      return mins > 0 ? mins : 1;
    }

    final responseSum = reviews
        .map((r) => r.responseMs ?? 0)
        .fold<int>(0, (a, b) => a + b);
    if (responseSum <= 0) return null;
    final mins = (responseSum / 60000).ceil();
    return mins > 0 ? mins : 1;
  }

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
    markStackCompleted(stack.id);
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
