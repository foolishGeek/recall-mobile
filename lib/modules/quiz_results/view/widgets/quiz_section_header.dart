import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

/// Section eyebrow: mono title (left) + an optional quiet mono note (right).
class QuizSectionHeader extends StatelessWidget {
  final String title;
  final String? note;

  const QuizSectionHeader({super.key, required this.title, this.note});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MonoLabel(title, size: 10, tracking: 0.2, color: c.grey500),
        if (note != null && note!.isNotEmpty)
          Text(
            note!,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.4,
              color: c.grey500,
            ),
          ),
      ],
    );
  }
}

/// Shared 1px hairline divider used inside the result cards.
class QuizRowDivider extends StatelessWidget {
  const QuizRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: c.grey200);
  }
}
