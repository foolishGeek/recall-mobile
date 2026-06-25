import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_typography.dart';
import '../../../core/widgets/mono_label.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/quiz_config_controller.dart';
import 'widgets/quiz_config_footer.dart';
import 'widgets/quiz_config_mode_top.dart';
import 'widgets/quiz_count_stepper.dart';
import 'widgets/quiz_difficulty_chips.dart';
import 'widgets/quiz_type_segmented.dart';

class QuizConfigView extends GetView<QuizConfigController> {
  const QuizConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return RecallScaffold.bare(
      body: Obx(
        () => RecallStateView(
          state: controller.viewState,
          errorMessage: controller.errorMessage,
          onRetry: controller.reload,
          child: _QuizConfigContent(controller: controller),
        ),
      ),
    );
  }
}

class _QuizConfigContent extends StatelessWidget {
  final QuizConfigController controller;

  const _QuizConfigContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 126),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(controller: controller),
              const SizedBox(height: 28),
              Text('Shape the round.',
                  style: t.displayMd.copyWith(color: c.ink)),
              const SizedBox(height: 10),
              Obx(() => Text(controller.subtitle,
                  style: t.body.copyWith(color: c.grey600, height: 1.35))),
              const SizedBox(height: 28),
              Obx(() => QuizConfigModeTop(controller: controller)),
              Obx(() {
                if (!controller.isFreehand) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: QuizConfigToggleRow(
                    label: 'Use my notes',
                    value: controller.useMyNotes.value,
                    onChanged: controller.setUseMyNotes,
                  ),
                );
              }),
              const SizedBox(height: 24),
              const MonoLabel('How many'),
              const SizedBox(height: 10),
              Obx(() => QuizCountStepper(
                    value: controller.questionCount.value,
                    onMinus: controller.decrementCount,
                    onPlus: controller.incrementCount,
                  )),
              const SizedBox(height: 24),
              const MonoLabel('Type'),
              const SizedBox(height: 10),
              Obx(() => QuizTypeSegmented(
                    value: controller.questionType.value,
                    onChanged: controller.setQuestionType,
                  )),
              const SizedBox(height: 24),
              const MonoLabel('Difficulty'),
              const SizedBox(height: 12),
              Obx(() => QuizDifficultyChips(
                    value: controller.difficulty.value,
                    onChanged: controller.setDifficulty,
                  )),
              const SizedBox(height: 24),
              Obx(() => QuizConfigToggleRow(
                    label: 'Per-question timer',
                    value: controller.timerEnabled.value,
                    onChanged: controller.setTimerEnabled,
                    caption: controller.timerEnabled.value
                        ? '${controller.timerSec.value} seconds'
                        : 'No timer',
                  )),
            ],
          ),
        ),
        QuizConfigFooter(controller: controller),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final QuizConfigController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: controller.onBackTap,
          child: Icon(Icons.chevron_left, color: c.grey500, size: 20),
        ),
        const SizedBox(width: 6),
        const MonoLabel('Quiz'),
        const SizedBox(width: 10),
        Obx(() => MonoLabel(controller.modeEyebrow, size: 9.5)),
      ],
    );
  }
}
