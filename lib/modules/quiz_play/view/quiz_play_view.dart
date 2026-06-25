import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/quiz_play_controller.dart';
import 'widgets/quiz_play_top_bar.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_self_rate_row.dart';
import 'widgets/quiz_submit_bar.dart';

class QuizPlayView extends GetView<QuizPlayController> {
  const QuizPlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.onEnd();
      },
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Obx(
          () => RecallStateView(
            state: controller.viewState,
            loading: const Center(child: CircularProgressIndicator.adaptive()),
            errorMessage: controller.errorMessage,
            onRetry: controller.onEnd,
            child: _PlayContent(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _PlayContent extends StatelessWidget {
  final QuizPlayController controller;

  const _PlayContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: topPad + 14),
            Obx(() => QuizPlayTopBar(
                  eyebrow: controller.eyebrow,
                  position: controller.displayPosition,
                  total: controller.total,
                  onEnd: controller.onEnd,
                )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                child: Column(
                  children: [
                    Expanded(
                      child: Obx(() => AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 360),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: _slide,
                            child: KeyedSubtree(
                              key: ValueKey(controller.currentIndex.value),
                              child: QuizQuestionCard(controller: controller),
                            ),
                          )),
                    ),
                    const SizedBox(height: 14),
                    _BottomAction(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Obx(() => QuizProgressBar(progress: controller.progress)),
        ),
      ],
    );
  }

  Widget _slide(Widget child, Animation<double> animation) {
    final offset = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final QuizPlayController controller;

  const _BottomAction({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Obx(() {
      final submitting = controller.submitting.value;
      final message = controller.inlineMessage.value;

      final Widget action;
      if (controller.isFlashcard) {
        action = controller.revealed.value
            ? QuizSelfRateRow(
                onRate: controller.onSelfRate,
                enabled: !submitting,
              )
            : QuizSubmitBar(
                label: 'Reveal',
                icon: Icons.visibility_outlined,
                loading: submitting,
                onTap: controller.onReveal,
              );
      } else {
        action = QuizSubmitBar(
          label: 'Submit answer',
          enabled: controller.canSubmit,
          loading: submitting,
          onTap: controller.onSubmit,
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600),
              ),
            ),
          action,
        ],
      );
    });
  }
}
