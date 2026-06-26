// Recall · All caught up empty state (docs/13_empty.md §B).

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
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
  final bool showReviewAhead;
  final bool isStartingAhead;
  final DoneFastBanner? doneFastBanner;
  final VoidCallback onReviewAhead;

  const EmptyTodayBody({
    super.key,
    required this.streak,
    required this.formattedDate,
    required this.nextDropAt,
    required this.hasNotes,
    required this.showReviewAhead,
    required this.isStartingAhead,
    required this.onReviewAhead,
    this.doneFastBanner,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        TodayTopBar(streak: streak, formattedDate: formattedDate),
        Expanded(
          child: Center(
            child: EmptyColumnReveal(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
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
                        "No cards due today. We'll surface your next batch "
                        'tomorrow morning — quietly, like always.',
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    if (showReviewAhead) ...[
                      const SizedBox(height: 30),
                      SecondaryButton(
                        label: 'Review ahead anyway',
                        trailing: Icons.arrow_forward,
                        onPressed: isStartingAhead ? null : onReviewAhead,
                      ),
                    ],
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
        ),
      ],
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

    return Column(
      children: [
        const SizedBox(height: 8),
        TodayTopBar(streak: streak, formattedDate: formattedDate),
        Expanded(
          child: Center(
            child: EmptyColumnReveal(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
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
        ),
      ],
    );
  }
}
