// Calm "Quiz is almost ready" sheet — replaces paywall redirects while Quiz
// modes are still shipping. Dismiss only; no Premium CTA.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class QuizInProgressSheet extends StatelessWidget {
  const QuizInProgressSheet({super.key});

  static Future<void> show() {
    return Get.bottomSheet(
      const QuizInProgressSheet(),
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.grey200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel('In progress', color: c.grey500, size: 9.5, tracking: 0.2),
            const SizedBox(height: 12),
            Text('Quiz is almost ready.',
                style: t.headingMd.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Text(
              'Practice modes are still being finished. Check back soon.',
              style: t.body.copyWith(color: c.grey600),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Got it',
                  style: t.label.copyWith(color: c.inkOnInk),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
