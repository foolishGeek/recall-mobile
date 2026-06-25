import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../controller/quiz_play_controller.dart';
import 'quiz_flashcard_panel.dart';
import 'quiz_mcq_options.dart';
import 'quiz_short_answer_field.dart';
import 'quiz_timer_chip.dart';

/// The one soft-rounded card (28px) that holds everything: source meta strip,
/// difficulty chip, the Fraunces question, and the type-specific answer.
class QuizQuestionCard extends StatelessWidget {
  final QuizPlayController controller;

  const QuizQuestionCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final q = controller.question;
    if (q == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.06),
            offset: const Offset(0, 10),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaStrip(c),
          const SizedBox(height: 18),
          _header(c),
          const SizedBox(height: 10),
          Text(
            q.prompt,
            style: GoogleFonts.fraunces(
              fontSize: 27,
              fontWeight: FontWeight.w500,
              height: 1.18,
              letterSpacing: -0.012 * 27,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 22),
          ..._body(c),
          const SizedBox(height: 18),
          _footer(c),
        ],
      ),
    );
  }

  Widget _metaStrip(RecallColors c) {
    final bucket = controller.question?.bucketName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'FROM — ${(bucket == null || bucket.isEmpty) ? 'YOUR NOTES' : bucket.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 10 * 0.18,
                    color: c.grey500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Timer takes the top-right slot when enabled; otherwise the difficulty
        // chip lives here (and moves beside the question number when timed).
        Obx(() => controller.hasTimer
            ? QuizTimerChip(
                remainingSec: controller.remainingSec.value,
                warning: controller.timerWarning.value,
              )
            : _difficultyChip()),
      ],
    );
  }

  Widget _header(RecallColors c) {
    final number = (controller.displayPosition).toString().padLeft(2, '0');
    return Row(
      children: [
        Text(
          'QUESTION $number',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 10.5 * 0.18,
            color: c.grey500,
          ),
        ),
        if (controller.hasTimer) ...[
          const SizedBox(width: 10),
          _difficultyChip(),
        ],
      ],
    );
  }

  Widget _difficultyChip() {
    final level = controller.difficultyLevel;
    if (level == null) return const SizedBox.shrink();
    return NeoChip.priority(level, label: controller.difficultyLabel);
  }

  List<Widget> _body(RecallColors c) {
    if (controller.isShort) {
      return [
        Expanded(
          child: Obx(() => QuizShortAnswerField(
                controller: controller.answerController,
                charCount: controller.charCount.value,
              )),
        ),
      ];
    }
    if (controller.isFlashcard) {
      return [
        Obx(() => QuizFlashcardPanel(
              revealed: controller.revealed.value,
              back: controller.flashcardBack.value ?? '',
            )),
        const Spacer(),
      ];
    }
    return [
      Obx(() => QuizMcqOptions(
            options: controller.question?.options ?? const [],
            selectedIndex: controller.selectedIndex.value,
            onSelect: controller.onSelectOption,
          )),
      const Spacer(),
    ];
  }

  Widget _footer(RecallColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 1, color: c.grey200),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: controller.onSkip,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next_outlined, size: 14, color: c.grey500),
                  const SizedBox(width: 6),
                  Text(
                    'Skip',
                    style: GoogleFonts.inter(fontSize: 12.5, color: c.grey500),
                  ),
                ],
              ),
            ),
            if (!controller.hasTimer)
              Text(
                'NO TIMER',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 10 * 0.14,
                  color: c.grey400,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
