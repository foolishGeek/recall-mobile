// Recall · All caught up empty state (docs/13_empty.md §B).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/recall_button.dart';
import '../../../../data/services/metrics_service.dart';
import '../../../today/view/widgets/today_top_bar.dart';
import 'empty_column_reveal.dart';
import 'empty_done_fast_banner.dart';
import 'empty_moon_illustration.dart';
import 'empty_next_drop_label.dart';

class EmptyTodayBody extends StatelessWidget {
  final int streak;
  final String formattedDate;
  final DateTime? nextDropAt;
  final bool hasNotes;
  final DoneFastBanner? doneFastBanner;
  final VoidCallback onOpenQuiz;

  const EmptyTodayBody({
    super.key,
    required this.streak,
    required this.formattedDate,
    required this.nextDropAt,
    required this.hasNotes,
    required this.onOpenQuiz,
    this.doneFastBanner,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TodayTopBar(streak: streak, formattedDate: formattedDate),
          Expanded(
            child: Center(
              child: EmptyColumnReveal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (doneFastBanner != null) ...[
                      EmptyDoneFastBanner(banner: doneFastBanner!),
                      const SizedBox(height: 18),
                    ],
                    const EmptyMoonIllustration(height: 140),
                    const SizedBox(height: 28),
                    Text(
                      "You're all caught up. Rest easy.",
                      textAlign: TextAlign.center,
                      style: t.displaySm.copyWith(fontSize: 32, height: 1.12),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        formatCaughtUpBody(
                          dropAt: nextDropAt,
                          hasNotes: hasNotes,
                        ),
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Quizzes let you revisit topics on your terms — '
                        'no due dates, no scores to lose.',
                        textAlign: TextAlign.center,
                        style: t.bodySm.copyWith(color: c.grey600, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _QuizQuietCta(onPressed: onOpenQuiz),
                    const SizedBox(height: 18),
                    EmptyNextDropLabel(
                      dropAt: nextDropAt,
                      hasNotes: hasNotes,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet secondary treat — quiz tab mark + brand line, matches SecondaryButton.
class _QuizQuietCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuizQuietCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: () {
        RecallHaptics.selection();
        onPressed();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1.5),
          borderRadius: BorderRadius.circular(RecallShape.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/tabs/quiz.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Text(
              'Quiz a quiet corner',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: c.grey500, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Quiet nudge when the user has no buckets yet (Today tab guard).
class EmptyTodayNoBucketsBody extends StatelessWidget {
  final int streak;
  final String formattedDate;
  final VoidCallback onMakeBucket;

  const EmptyTodayNoBucketsBody({
    super.key,
    required this.streak,
    required this.formattedDate,
    required this.onMakeBucket,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TodayTopBar(streak: streak, formattedDate: formattedDate),
          Expanded(
            child: Center(
              child: EmptyColumnReveal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start with a bucket',
                      textAlign: TextAlign.center,
                      style: t.headingMd.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Make your first bucket to tuck notes inside — '
                        'Recall will schedule your reviews from there.',
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Make your first bucket',
                      height: 52,
                      onPressed: onMakeBucket,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
