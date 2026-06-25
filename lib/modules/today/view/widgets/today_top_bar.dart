import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import 'streak_icon.dart';

class TodayTopBar extends StatelessWidget {
  final int streak;
  final String formattedDate;

  const TodayTopBar({
    super.key,
    required this.streak,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreakIcon(color: c.ink),
            const SizedBox(width: 9),
            Text(
              '$streak',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.ink,
                letterSpacing: 14 * -0.01,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'day streak',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.grey500,
              ),
            ),
          ],
        ),
        MonoLabel(formattedDate, size: 11, tracking: 0.16),
      ],
    );
  }
}
