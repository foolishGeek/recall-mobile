// Recall · Insights chrome — the top-bar tier badges. FREE is a quiet outline
// pill; PREMIUM is a solid-ink pill; PRO (on locked teasers) is the same solid
// ink mark. These never use color — tier status is conveyed by weight only.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

/// Solid-ink badge: PREMIUM (top bar) and PRO (locked tiles).
class InsightsSolidBadge extends StatelessWidget {
  final String label;
  const InsightsSolidBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: t.monoLabelSm.copyWith(
          color: c.inkOnInk,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Outline badge: FREE (top bar).
class InsightsOutlineBadge extends StatelessWidget {
  final String label;
  const InsightsOutlineBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: c.grey400, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: t.monoLabelSm.copyWith(
          color: c.grey500,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Top bar: mono "INSIGHTS" left · tier badge right.
class InsightsTopBar extends StatelessWidget {
  final bool premium;
  const InsightsTopBar({super.key, required this.premium});

  @override
  Widget build(BuildContext context) {
    final t = RecallType.of(context);
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'INSIGHTS',
          style: t.monoCaption.copyWith(color: c.grey500, letterSpacing: 1.6),
        ),
        premium
            ? const InsightsSolidBadge(label: 'PREMIUM')
            : const InsightsOutlineBadge(label: 'FREE'),
      ],
    );
  }
}

/// Title row: Fraunces title + mono caption underneath.
class InsightsTitle extends StatelessWidget {
  final String caption;
  const InsightsTitle({super.key, required this.caption});

  @override
  Widget build(BuildContext context) {
    final t = RecallType.of(context);
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights', style: t.displayMd),
        const SizedBox(height: 6),
        Text(
          caption.toUpperCase(),
          style: t.monoCaption.copyWith(color: c.grey500, letterSpacing: 1.2),
        ),
      ],
    );
  }
}
