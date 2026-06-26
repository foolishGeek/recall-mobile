import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/empty_controller.dart';
import '../empty_variant.dart';
import 'widgets/empty_buckets_body.dart';
import 'widgets/empty_insights_body.dart';
import 'widgets/empty_today_body.dart';

/// Deep-link fallback for `/empty/*` routes. Tab bodies render inline in the
/// shell; this view keeps the tab bar active per docs/13_empty.md.
class EmptyView extends GetView<EmptyController> {
  final EmptyVariant variant;

  const EmptyView({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallScaffold(
        activeTab: controller.activeTab,
        body: RecallStateView(
          state: controller.viewState,
          errorMessage: controller.errorMessage,
          onRetry: controller.reload,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    switch (variant) {
      case EmptyVariant.buckets:
        return EmptyBucketsBody(onMakeBucket: controller.onMakeBucket);
      case EmptyVariant.today:
        return Obx(
          () => EmptyTodayBody(
            streak: controller.streak.value,
            formattedDate: controller.formattedDate.value,
            nextDropAt: controller.nextDropAt.value,
            hasNotes: controller.hasNotes.value,
            showReviewAhead: controller.showReviewAhead.value,
            isStartingAhead: controller.isStartingAhead.value,
            doneFastBanner: controller.doneFastBanner.value,
            onReviewAhead: controller.onReviewAhead,
          ),
        );
      case EmptyVariant.insights:
        return Obx(
          () => EmptyInsightsBody(
            days: controller.daysWithReviews.value,
            onStart: controller.onStartReview,
          ),
        );
    }
  }
}
