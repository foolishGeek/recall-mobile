// Recall · MetricsService (stub — implemented in S04). Post-hardening (migration
// 00003), streak/XP/level/daily_activity/achievements/usage are written by
// server-side DB triggers, so this is a READ/ORCHESTRATION layer: each hook
// persists the client-owned rows (reviews/stacks via repositories) and then
// re-reads the server-computed profile/activity to refresh the UI. No direct
// writes to those server-authoritative columns. Bodies land in S04.

import 'package:get/get.dart';

import '../models/models.dart';

class MetricsService extends GetxService {
  /// Called after a review is persisted. The DB trigger has already updated
  /// daily_activity, streak, XP/level, and review-driven achievements; S04 will
  /// re-read the profile here and expose the deltas for celebratory UI.
  Future<void> onReviewRecorded(Review review, Profile profile) async {
    // TODO(S04): re-read profile/activity; surface XP/streak deltas.
  }

  /// Called when a stack is created. The stack-limit + usage increment are
  /// enforced server-side (00003 trigger); S04 wires post-create refresh.
  Future<void> onStackStarted(Stack stack, Profile profile) async {
    // TODO(S04): refresh monthly usage / caught-up state.
  }

  /// Called when a stack is completed. Stack XP + achievements are awarded by
  /// the 00003 trigger; S04 re-reads for the completion screen.
  Future<void> onStackCompleted(Stack stack, Profile profile) async {
    // TODO(S04): re-read profile; drive "all caught up" metrics [D-UI-3].
  }
}
