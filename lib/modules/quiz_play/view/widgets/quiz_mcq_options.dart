import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// Four ink-bordered choice pills. Selecting flips the whole row to solid ink
/// with a check on the right (240ms). Nothing reveals correctness — that lives
/// in Results.
class QuizMcqOptions extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const QuizMcqOptions({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        for (var i = 0; i < options.length && i < 4; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _OptionRow(
            colors: c,
            dark: dark,
            letter: _letters[i],
            text: options[i],
            selected: selectedIndex == i,
            onTap: () => onSelect(i),
          ),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final RecallColors colors;
  final bool dark;
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.colors,
    required this.dark,
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final fg = selected ? c.inkOnInk : c.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.canvas,
          border: Border.all(color: selected ? c.ink : c.grey200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.ink.withValues(alpha: dark ? 0.4 : 0.18),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.canvas : c.card,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: c.grey200),
              ),
              child: Text(
                letter,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? c.ink : c.grey600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: fg,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              Icon(Icons.check, size: 16, color: c.inkOnInk),
            ],
          ],
        ),
      ),
    );
  }
}
