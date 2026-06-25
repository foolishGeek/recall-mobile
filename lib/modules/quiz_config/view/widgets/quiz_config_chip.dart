import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

class QuizConfigChip extends StatelessWidget {
  final String label;
  final String? meta;
  final bool selected;
  final VoidCallback onTap;

  const QuizConfigChip({
    super.key,
    required this.label,
    this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.cardSunken,
          border: Border.all(color: selected ? c.ink : c.grey200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 13, color: c.inkOnInk),
              const SizedBox(width: 6),
            ],
            Text(
              meta == null ? label : '$label  $meta',
              style: t.labelSm.copyWith(
                color: selected ? c.inkOnInk : c.grey600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
