import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../data/models/models.dart';
import '../../controller/quiz_home_controller.dart';
import 'quiz_mode_card.dart';
import 'recent_quiz_chip.dart';

class QuizHomeModeCards extends StatelessWidget {
  final QuizHomeController controller;

  const QuizHomeModeCards({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ModeSpec(
        mode: QuizMode.freehand,
        icon: Icons.edit_outlined,
        title: 'Free-hand',
        body: 'Tell us what to quiz you on, in your own words.',
      ),
      _ModeSpec(
        mode: QuizMode.byBucket,
        icon: Icons.layers_outlined,
        title: 'By bucket',
        body: 'Choose one or more buckets and we\'ll mix the questions.',
      ),
      _ModeSpec(
        mode: QuizMode.byNode,
        icon: Icons.article_outlined,
        title: 'By node',
        body: 'Pick a single note to drill into.',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          _StaggeredCard(
            controller: controller,
            index: i,
            child: QuizModeCard(
              icon: cards[i].icon,
              title: cards[i].title,
              body: cards[i].body,
              locked: controller.locked,
              onTap: () => controller.onModeTap(cards[i].mode),
            ),
          ),
          if (i != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Quiet entry to continue an interrupted, still-in-progress attempt. Questions
/// are re-fetched redacted from the server — the answer key never leaves it.
class QuizHomeResumeCard extends StatelessWidget {
  final QuizHomeController controller;

  const QuizHomeResumeCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return GestureDetector(
      onTap: controller.onResume,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.ink, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, size: 20, color: c.inkOnInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoLabel('Resume quiz'),
                  const SizedBox(height: 3),
                  Text(
                    controller.resumeLabel,
                    style: t.bodySm.copyWith(color: c.grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Obx(() => controller.resuming.value
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
                  )
                : Icon(Icons.chevron_right, size: 20, color: c.grey400)),
          ],
        ),
      ),
    );
  }
}

class QuizHomeRecentQuizzes extends StatelessWidget {
  final QuizHomeController controller;

  const QuizHomeRecentQuizzes({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoLabel('Recent quizzes'),
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.recentAttempts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final attempt = controller.recentAttempts[index];
                return RecentQuizChip(label: controller.recentLabel(attempt));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredCard extends StatelessWidget {
  final QuizHomeController controller;
  final int index;
  final Widget child;

  const _StaggeredCard({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: controller.staggerController,
      builder: (context, child) {
        final start = index * 0.12;
        final anim = CurvedAnimation(
          parent: controller.staggerController,
          curve: Interval(
            start,
            (start + 0.64).clamp(0.0, 1.0),
            curve: RecallMotion.easeOut,
          ),
        );
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 6),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ModeSpec {
  final QuizMode mode;
  final IconData icon;
  final String title;
  final String body;

  const _ModeSpec({
    required this.mode,
    required this.icon,
    required this.title,
    required this.body,
  });
}
