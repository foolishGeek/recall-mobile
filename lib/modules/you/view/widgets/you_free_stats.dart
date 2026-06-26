// Recall · You free stat row. The same XP / streak / reviews trio premium users
// have, in a calm 3-up. XP + streak from profiles, reviews from
// v_profile_lifetime.total_reviews. All server truth.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_number.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class YouFreeStats extends StatelessWidget {
  final int xp;
  final int streak;
  final int reviews;

  const YouFreeStats({
    super.key,
    required this.xp,
    required this.streak,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'XP', value: RecallNumber.grouped(xp))),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Streak',
            value: RecallNumber.grouped(streak),
            unit: 'd',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(label: 'Reviews', value: RecallNumber.grouped(reviews)),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  const _MiniStat({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(label, size: 9, tracking: 0.16),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.52,
                  color: c.ink,
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: c.grey600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
