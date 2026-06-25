import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../data/models/models.dart';

class QuizTypeSegmented extends StatelessWidget {
  final QuizQuestionType value;
  final ValueChanged<QuizQuestionType> onChanged;

  const QuizTypeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final items = {
      QuizQuestionType.mcq: 'MCQ',
      QuizQuestionType.shortAnswer: 'Short',
      QuizQuestionType.flashcard: 'Flash',
      QuizQuestionType.mix: 'Mix',
    };
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.cardSunken,
        border: Border.all(color: c.grey200),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: _Segment(
                label: entry.value,
                selected: value == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
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
        duration: RecallMotion.normal,
        curve: RecallMotion.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.card : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: RecallMotion.normal,
          child: Text(
            label,
            key: ValueKey('$label$selected'),
            style: t.labelSm.copyWith(
              color: selected ? c.ink : c.grey500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
