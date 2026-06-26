// Recall · You lifetime stats (premium). Four numbers of equal weight in mono
// captions: memories saved (profiles.memories_saved), recalls logged + nodes
// captured + lifetime adherence (v_profile_lifetime [D-VIEW-3]). All server
// truth — adherence is "—" when there were no due reviews to adhere to.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_number.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class YouLifetimeCard extends StatelessWidget {
  final int memoriesSaved;
  final int totalReviews;
  final int totalNodes;
  final double? adherencePct;
  final String? sinceLabel;

  const YouLifetimeCard({
    super.key,
    required this.memoriesSaved,
    required this.totalReviews,
    required this.totalNodes,
    required this.adherencePct,
    required this.sinceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const MonoLabel('Lifetime', size: 9.5, tracking: 0.18),
              const Spacer(),
              if (sinceLabel != null)
                Text(
                  sinceLabel!,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5, color: c.grey500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 14,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _LifetimeStat(
                  value: RecallNumber.grouped(memoriesSaved),
                  label: 'memories saved'),
              _LifetimeStat(
                  value: RecallNumber.grouped(totalReviews),
                  label: 'recalls logged'),
              _LifetimeStat(
                  value: RecallNumber.grouped(totalNodes),
                  label: 'nodes captured'),
              _LifetimeStat(
                value: adherencePct == null ? '—' : '${adherencePct!.round()}',
                unit: adherencePct == null ? null : '%',
                label: 'lifetime adherence',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LifetimeStat extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  const _LifetimeStat({required this.value, this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.56,
                color: c.ink,
              ),
            ),
            if (unit != null)
              Text(
                unit!,
                style: GoogleFonts.fraunces(fontSize: 15, color: c.grey600),
              ),
          ],
        ),
        const SizedBox(height: 4),
        MonoLabel(label, size: 9.5, tracking: 0.06),
      ],
    );
  }
}
