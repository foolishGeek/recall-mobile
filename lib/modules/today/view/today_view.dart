import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/how_it_works_copy.dart';
import '../../../core/widgets/recall_coach_tip.dart';
import '../../../core/widgets/recall_skeleton.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../empty/view/widgets/empty_today_body.dart';
import '../controller/today_controller.dart';
import 'widgets/today_cards_progress.dart';
import 'widgets/today_peeking_stack.dart';
import 'widgets/today_relearn_card.dart';
import 'widgets/today_stacks_meter.dart';
import 'widgets/today_start_cta.dart';
import 'widgets/today_top_bar.dart';

class TodayView extends GetView<TodayController> {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        loading: const _TodaySkeleton(),
        errorMessage: controller.errorMessage,
        onRetry: controller.reload,
        child: _TodayContent(controller: controller),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final TodayController controller;
  const _TodayContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isNoBuckets) {
        return EmptyTodayNoBucketsBody(
          streak: controller.currentStreak,
          formattedDate: controller.formattedDate,
          onMakeBucket: controller.onMakeBucket,
        );
      }
      if (controller.isAllCaughtUp) {
        return EmptyTodayBody(
          streak: controller.currentStreak,
          formattedDate: controller.formattedDate,
          nextDropAt: controller.nextDropAt.value,
          hasNotes: controller.hasNotes,
          pushEnabled: controller.pushEnabled,
          dropFrequency: controller.dropFrequency,
          doneFastBanner: controller.doneFastBanner.value,
          onOpenQuiz: controller.openQuiz,
          onAddNote: controller.onAddNote,
          onDropFrequencyChanged: controller.setDropFrequency,
        );
      }
      return _TodayLoaded(controller: controller);
    });
  }
}

class _TodayLoaded extends StatelessWidget {
  final TodayController controller;
  const _TodayLoaded({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Obx(() {
                      final _ = controller.profile.value;
                      return TodayTopBar(
                        streak: controller.currentStreak,
                        formattedDate: controller.formattedDate,
                      );
                    }),
                    const SizedBox(height: 22),
                    Obx(() {
                      if (!controller.showDueCoachTip.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: RecallCoachTip(
                          text: HowItWorksCopy.todayTip,
                          howItWorksTitle: HowItWorksCopy.todayTitle,
                          howItWorksSections: HowItWorksCopy.todaySections,
                          onDismiss: controller.dismissDueCoachTip,
                        ),
                      );
                    }),
                    const SizedBox(height: 26),
                    Obx(() => TodayCardsProgress(
                          remaining: controller.cardsRemaining,
                          total: controller.sessionTotal,
                        )),
                    const SizedBox(height: 30),
                    // Stack sits right under the hero; the action dock (Aura
                    // whisper + Start CTA) is pushed to the bottom by Spacer.
                    Obx(() {
                      final nodes = controller.peekingNodes.toList();
                      return TodayPeekingStack(
                        nodes: nodes,
                        animation: controller.cardController,
                      );
                    }),
                    const Spacer(),
                    Obx(() {
                      if (!controller.showRelearn) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TodayRelearnCard(
                          count: controller.relearnCount,
                          isStarting: controller.isRelearnStarting.value,
                          onStart: controller.startRelearn,
                          onDismiss: controller.dismissRelearn,
                        ),
                      );
                    }),
                    Obx(() => TodayStartCta(
                          label: controller.reviewCtaLabel,
                          isLoading: controller.isStarting.value,
                          onPressed: controller.onReviewCta,
                        )),
                    Obx(() {
                      if (!controller.showStacksMeter) {
                        return const SizedBox(height: 16);
                      }
                      return TodayStacksMeter(
                        stacksUsed: controller.stacksUsed.value,
                        maxStacks: controller.stacksCap,
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              RecallSkeleton(width: 140, height: 18, phase: 0),
              RecallSkeleton(width: 60, height: 14, phase: 0.2),
            ],
          ),
          const SizedBox(height: 34),
          const RecallSkeleton(width: 150, height: 52, phase: 0.35),
          const SizedBox(height: 14),
          const RecallSkeleton(width: 130, height: 13, phase: 0.42),
          const SizedBox(height: 20),
          const RecallSkeleton(
            width: 104,
            height: 3,
            borderRadius: BorderRadius.all(Radius.circular(1.5)),
            phase: 0.48,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 176,
            child: Stack(
              children: const [
                Positioned(
                  top: 0,
                  left: 18,
                  right: 18,
                  child: RecallSkeleton(
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    phase: 0.5,
                  ),
                ),
                Positioned(
                  top: 28,
                  left: 9,
                  right: 9,
                  child: RecallSkeleton(
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(23)),
                    phase: 0.65,
                  ),
                ),
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RecallSkeleton(
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(26)),
                    phase: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const RecallSkeleton(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
            phase: 0.9,
          ),
        ],
      ),
    );
  }
}
