// Recall · Insights stat grid (2×2). The four numbers that prove a habit is
// forming: streak, 7-day adherence, due today, overdue. Numerals in Fraunces,
// units in mono. Shame-free: adherence with no due reviews reads "—" (never a
// red fail); overdue 0 stays visible in grey500 (never collapses).

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/soft_card.dart';

class InsightsStatGrid extends StatelessWidget {
  final int streak;
  final double? adherencePct;
  final int dueToday;
  final int overdue;

  const InsightsStatGrid({
    super.key,
    required this.streak,
    required this.adherencePct,
    required this.dueToday,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final adherence =
        adherencePct == null ? '—' : adherencePct!.round().toString();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '$streak',
                unit: streak == 1 ? 'day' : 'days',
                label: 'Streak',
                muted: streak == 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCell(
                value: adherence,
                unit: adherencePct == null ? '' : '%',
                label: 'Adherence',
                muted: adherencePct == null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '$dueToday',
                unit: dueToday == 1 ? 'card' : 'cards',
                label: 'Due today',
                muted: dueToday == 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCell(
                value: '$overdue',
                unit: overdue == 1 ? 'card' : 'cards',
                label: 'Overdue',
                muted: overdue == 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final bool muted;

  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: t.numeralLg.copyWith(
                  fontSize: 34,
                  color: muted ? c.grey500 : c.ink,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: t.monoCaption.copyWith(color: c.grey500),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: t.monoLabelSm.copyWith(color: c.grey500, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}
