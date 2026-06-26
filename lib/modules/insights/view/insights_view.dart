// Recall · InsightsView. The proof-of-value ledger. Renders one of three states
// inside the Insights tab: the portrait gate (<7 days), the free variant (stat
// grid + heatmap + locked teasers + unlock CTA), or the premium variant
// (retention hero + curve, mastery, weak topics, velocity + Drop-open). Pure
// UI: every number comes from the controller's server-authoritative loads.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/recall_button.dart';
import '../../../core/widgets/staggered_reveal.dart';
import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_typography.dart';
import '../controller/insights_controller.dart';
import 'widgets/insights_cards.dart';
import 'widgets/insights_chrome.dart';
import '../../empty/view/widgets/empty_insights_body.dart';
import 'widgets/insights_locked_block.dart';
import 'widgets/insights_stat_grid.dart';

class InsightsView extends GetView<InsightsController> {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        errorMessage: controller.errorMessage,
        onRetry: controller.reload,
        child: Obx(() {
          if (controller.isGated.value) {
            return EmptyInsightsBody(
              days: controller.daysWithReviews.value,
              onStart: controller.onStartReview,
            );
          }
          return controller.isPremium
              ? _PremiumBody(controller: controller)
              : _FreeBody(controller: controller);
        }),
      ),
    );
  }
}

/// Wraps the column children in the 60ms card-arrival stagger.
class _StaggeredColumn extends StatelessWidget {
  final InsightsController controller;
  final List<Widget> children;
  const _StaggeredColumn({required this.controller, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            StaggeredReveal(
              index: i,
              controller: controller.staggerController,
              child: children[i],
            ),
            if (i != children.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _FreeBody extends StatelessWidget {
  final InsightsController controller;
  const _FreeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final teaserNodes = controller.totalNodes.value;
    return _StaggeredColumn(
      controller: controller,
      children: [
        const InsightsTopBar(premium: false),
        const InsightsTitle(caption: 'Last 12 weeks'),
        InsightsStatGrid(
          streak: controller.streak,
          adherencePct: controller.adherencePct,
          dueToday: controller.dueToday,
          overdue: controller.overdue,
        ),
        InsightsHeatmapCard(grid: controller.heatmap.value),
        InsightsLockedBlock(
          title: 'Forgetting curve',
          body: 'See your retention curve — with Recall vs. without.',
          preview: LockedCurvePreview(
            cachedWithRecall: controller.cachedWithRecall.value,
            cachedBaseline: controller.cachedBaseline.value,
          ),
          teaser: teaserNodes > 0
              ? 'Recall is protecting $teaserNodes '
                  '${teaserNodes == 1 ? "note" : "notes"} from fading.'
              : null,
          onTap: () => controller.onLockedBlockTap('forgetting_curve'),
        ),
        InsightsLockedBlock(
          title: 'Mastery & weak topics',
          body: 'Track how each bucket is holding and what needs a nudge.',
          preview: const LockedMasteryPreview(),
          onTap: () => controller.onLockedBlockTap('mastery'),
        ),
        _UnlockCta(onTap: controller.onUnlockTap),
      ],
    );
  }
}

class _PremiumBody extends StatelessWidget {
  final InsightsController controller;
  const _PremiumBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final retention = controller.retention.value;
    return _StaggeredColumn(
      controller: controller,
      children: [
        const InsightsTopBar(premium: true),
        const InsightsTitle(caption: 'Last 12 weeks · all buckets'),
        if (retention != null)
          InsightsRetentionCard(
            retention: retention,
            firstReveal: controller.firstRetentionReveal,
          ),
        InsightsHeatmapCard(grid: controller.heatmap.value),
        InsightsMasteryCard(
          rings: controller.masteryRings.toList(),
          bucketCount: controller.bucketCount.value,
        ),
        InsightsWeakTopicsCard(topics: controller.weakTopics.toList()),
        InsightsVelocityDropsRow(
          avgVelocity: controller.avgVelocity,
          velocity: controller.velocity.toList(),
          stats: controller.notifStats.value,
          daily: controller.notifDaily.toList(),
        ),
      ],
    );
  }
}

class _UnlockCta extends StatelessWidget {
  final VoidCallback onTap;
  const _UnlockCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: 'Unlock the full picture',
          height: 52,
          onPressed: onTap,
        ),
        const SizedBox(height: 10),
        Text(
          "See exactly how much you'd forget without Recall.",
          textAlign: TextAlign.center,
          style: t.bodySm.copyWith(color: c.grey500),
        ),
      ],
    );
  }
}
