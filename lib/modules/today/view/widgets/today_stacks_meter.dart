import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class TodayStacksMeter extends StatelessWidget {
  final int stacksUsed;
  final int maxStacks;

  const TodayStacksMeter({
    super.key,
    required this.stacksUsed,
    this.maxStacks = 2,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final remaining = (maxStacks - stacksUsed).clamp(0, maxStacks);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Row(
            children: List.generate(maxStacks, (i) {
              final filled = i < stacksUsed;
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                child: Container(
                  width: 26,
                  height: 5,
                  decoration: BoxDecoration(
                    color: filled ? c.ink : c.grey400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Text(
            '$remaining of $maxStacks stacks left this month',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: c.grey500,
              letterSpacing: 10.5 * 0.04,
            ),
          ),
        ],
      ),
    );
  }
}
