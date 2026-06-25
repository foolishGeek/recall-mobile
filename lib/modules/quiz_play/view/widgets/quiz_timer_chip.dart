import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// Small mono "00:24" countdown shown only when the round had a timer. At the
/// warning threshold it softens (still monochrome) and gives a single nudge.
class QuizTimerChip extends StatelessWidget {
  final int remainingSec;
  final bool warning;

  const QuizTimerChip({
    super.key,
    required this.remainingSec,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final color = warning ? c.grey500 : c.ink;
    final mm = (remainingSec ~/ 60).toString().padLeft(2, '0');
    final ss = (remainingSec % 60).toString().padLeft(2, '0');

    return AnimatedScale(
      scale: warning ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 11, color: color),
          const SizedBox(width: 6),
          Text(
            '$mm:$ss',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
