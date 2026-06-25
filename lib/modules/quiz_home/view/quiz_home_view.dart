import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_typography.dart';
import '../../../core/widgets/mono_label.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/quiz_home_controller.dart';
import 'widgets/quiz_home_pro_badge.dart';
import 'widgets/quiz_home_sections.dart';

class QuizHomeView extends GetView<QuizHomeController> {
  const QuizHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        errorMessage: controller.errorMessage,
        onRetry: controller.reload,
        child: _QuizHomeContent(controller: controller),
      ),
    );
  }
}

class _QuizHomeContent extends StatelessWidget {
  final QuizHomeController controller;

  const _QuizHomeContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(controller: controller),
          const SizedBox(height: 26),
          Text(
            'Quiz a quiet\ncorner of you.',
            style: t.displayLg.copyWith(color: c.ink, height: 1.0),
          ),
          const SizedBox(height: 12),
          Text(
            'Three ways to start. No streaks, no scores you can lose.',
            style: t.body.copyWith(color: c.grey600, height: 1.35),
          ),
          Obx(() {
            if (controller.resumable.value == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: QuizHomeResumeCard(controller: controller),
            );
          }),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              MonoLabel('Choose a mode'),
              MonoLabel('3 of 3', size: 9.5),
            ],
          ),
          const SizedBox(height: 12),
          QuizHomeModeCards(controller: controller),
          Obx(() {
            if (controller.recentAttempts.isEmpty) return const SizedBox();
            return QuizHomeRecentQuizzes(controller: controller);
          }),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final QuizHomeController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    const gap = SizedBox(width: 8);
    return Row(
      children: [
        const MonoLabel('Quiz'),
        gap,
        Obx(() => QuizHomeProBadge(active: controller.isPremiumRx)),
        const Spacer(),
        Icon(Icons.search, size: 18, color: c.ink),
      ],
    );
  }
}
