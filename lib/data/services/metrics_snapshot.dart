// Recall · Metrics snapshots returned after server-side trigger refresh.

import '../models/profile.dart';

class ReviewMetricsSnapshot {
  final Profile profile;
  final int xpDelta;
  final int streakDelta;
  final bool levelIncreased;
  final double? adherence7d;

  const ReviewMetricsSnapshot({
    required this.profile,
    this.xpDelta = 0,
    this.streakDelta = 0,
    this.levelIncreased = false,
    this.adherence7d,
  });
}

class StackUsageSnapshot {
  final int stacksCreatedThisMonth;

  const StackUsageSnapshot({required this.stacksCreatedThisMonth});
}

class StackCompletedSnapshot {
  final Profile profile;
  final int? durationMinutes;
  final bool fasterThanUsual;

  const StackCompletedSnapshot({
    required this.profile,
    this.durationMinutes,
    this.fasterThanUsual = false,
  });
}
