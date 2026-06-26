// Recall · InsightsEmpty portrait gate (days 1–6). Rendered inside the Insights
// tab so the tab bar stays active (docs/13_empty.md §C). One ink-line
// illustration + an editorial reassurance + a 7-pill progress row that turns
// the wait into a visible goal-gradient. The word "empty" never appears.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/recall_button.dart';
import 'insights_chrome.dart';

class InsightsEmptyBody extends StatelessWidget {
  final int days;
  final VoidCallback onStart;

  const InsightsEmptyBody({super.key, required this.days, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final filled = days.clamp(0, 7);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INSIGHTS',
                  style: t.monoCaption
                      .copyWith(color: c.grey500, letterSpacing: 1.6)),
              Text('DAY $filled / 7',
                  style: t.monoCaption
                      .copyWith(color: c.grey500, letterSpacing: 1.4)),
            ],
          ),
          const SizedBox(height: 22),
          const InsightsTitle(caption: 'Drawing your portrait'),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/illustrations/empty-portrait-progress.svg',
                  height: 120,
                  colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                ),
                const SizedBox(height: 28),
                Text('A portrait in progress.',
                    style: t.displaySm.copyWith(fontSize: 30)),
                const SizedBox(height: 14),
                Text(
                  'Recall needs a few more days of reviews to draw your '
                  'retention curve. Keep showing up — the picture starts to '
                  'fill in around day seven.',
                  textAlign: TextAlign.center,
                  style: t.body.copyWith(color: c.grey600),
                ),
                const SizedBox(height: 26),
                _ProgressPills(filled: filled),
                const SizedBox(height: 10),
                Text('$filled / 7 days',
                    style: t.monoCaption.copyWith(color: c.grey500)),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: "Start today's review",
                  height: 48,
                  onPressed: onStart,
                ),
              ],
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
            width: 26,
            height: 6,
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
