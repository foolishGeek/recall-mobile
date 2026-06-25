import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/enums.dart';

/// Flashcard self-rating: Forgot / Hard / Good / Easy. Stored as the grade;
/// scheduling happens on the backend at quiz-complete.
class QuizSelfRateRow extends StatelessWidget {
  final ValueChanged<ReviewGrade> onRate;
  final bool enabled;

  const QuizSelfRateRow({
    super.key,
    required this.onRate,
    this.enabled = true,
  });

  static const _grades = [
    (ReviewGrade.again, 'Forgot'),
    (ReviewGrade.hard, 'Hard'),
    (ReviewGrade.good, 'Good'),
    (ReviewGrade.easy, 'Easy'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        for (var i = 0; i < _grades.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _RateButton(
              colors: c,
              dark: dark,
              label: _grades[i].$2,
              primary: _grades[i].$1 == ReviewGrade.good,
              onTap: enabled ? () => onRate(_grades[i].$1) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  final RecallColors colors;
  final bool dark;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _RateButton({
    required this.colors,
    required this.dark,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final bg = primary ? c.ink : c.card;
    final fg = primary ? c.inkOnInk : c.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: c.ink, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
