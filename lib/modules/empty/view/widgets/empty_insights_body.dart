// Recall · Insights portrait gate (docs/13_empty.md §C).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/recall_button.dart';
import '../../../insights/view/widgets/insights_chrome.dart';
import 'empty_column_reveal.dart';

class EmptyInsightsBody extends StatelessWidget {
  final int days;
  final VoidCallback onStart;

  const EmptyInsightsBody({
    super.key,
    required this.days,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final filled = days.clamp(0, 7);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INSIGHTS',
                style: t.monoCaption
                    .copyWith(color: c.grey500, letterSpacing: 1.6),
              ),
              Text(
                'DAY $filled / 7',
                style: t.monoCaption
                    .copyWith(color: c.grey500, letterSpacing: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const InsightsTitle(caption: 'Drawing your portrait'),
          const SizedBox(height: 40),
          EmptyColumnReveal(
            child: Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/illustrations/empty-portrait-progress.svg',
                    height: 120,
                    colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'A portrait in progress.',
                    style: t.displaySm.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 280,
                    child: Text(
                      'Recall needs a few more days of reviews to draw your '
                      'retention curve. Keep showing up — the picture starts '
                      'to fill in around day seven.',
                      textAlign: TextAlign.center,
                      style: t.body.copyWith(color: c.grey600),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _ProgressPills(filled: filled),
                  const SizedBox(height: 10),
                  Text(
                    '$filled / 7 days',
                    style: t.monoCaption.copyWith(color: c.grey500),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: "Start today's review",
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    onPressed: onStart,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPills extends StatelessWidget {
  final int filled;
  const _ProgressPills({required this.filled});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : Duration(milliseconds: 220 + i * 80),
            curve: RecallMotion.easeOut,
            width: 18,
            height: 5,
            decoration: BoxDecoration(
              color: isFilled ? c.ink : c.grey400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
