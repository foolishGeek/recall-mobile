import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/quiz_results_controller.dart';
import 'widgets/quiz_breakdown.dart';
import 'widgets/quiz_comfort_update.dart';
import 'widgets/quiz_results_footer.dart';
import 'widgets/quiz_results_top_bar.dart';
import 'widgets/quiz_score_hero.dart';
import 'widgets/quiz_watchlist.dart';

class QuizResultsView extends GetView<QuizResultsController> {
  const QuizResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.onDone();
      },
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Obx(
          () => RecallStateView(
            state: controller.viewState,
            loading: const Center(child: CircularProgressIndicator.adaptive()),
            errorMessage: controller.errorMessage,
            onRetry: controller.retry,
            child: const _ResultsContent(),
          ),
        ),
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizResultsController>();
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: topPad + 14),
            Obx(() => QuizResultsTopBar(
                  header: controller.header,
                  onDone: controller.onDone,
                  onShare: controller.onShare,
                )),
            Expanded(
              child: Obx(() {
                final data = controller.data;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
                  children: [
                    QuizScoreHero(
                      score: controller.scoreInt,
                      correct: data.correct,
                      total: data.total,
                      headline: controller.headline,
                      caption: controller.caption,
                      celebrate: controller.celebrate,
                    ),
                    QuizBreakdown(questions: data.questions),
                    if (data.weakTopics.isNotEmpty) const SizedBox(height: 24),
                    QuizWatchlist(
                      topics: data.weakTopics,
                      onTap: controller.onWeakTopicTap,
                    ),
                    if (data.comfortUpdates.isNotEmpty) const SizedBox(height: 24),
                    QuizComfortUpdateSection(updates: data.comfortUpdates),
                  ],
                );
              }),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Obx(() => QuizResultsFooter(
                showReviewMissed: controller.hasReviewMissed,
                buildingStack: controller.buildingStack.value,
                onReviewMissed: controller.onReviewMissed,
                onDone: controller.onDone,
              )),
        ),
      ],
    );
  }
}
