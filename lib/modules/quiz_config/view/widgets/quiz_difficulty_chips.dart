import 'package:flutter/material.dart';

import '../../../../core/widgets/neo_chip.dart';

class QuizDifficultyChips extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const QuizDifficultyChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Choice(
          value: 2,
          selected: value == 2,
          onTap: onChanged,
          child: NeoChip.priority(NeoLevel.low, label: 'EASY'),
        ),
        const SizedBox(width: 10),
        _Choice(
          value: 3,
          selected: value == 3,
          onTap: onChanged,
          child: NeoChip.priority(NeoLevel.medium, label: 'MED'),
        ),
        const SizedBox(width: 10),
        _Choice(
          value: 4,
          selected: value == 4,
          onTap: onChanged,
          child: NeoChip.priority(NeoLevel.high, label: 'HARD'),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final int value;
  final bool selected;
  final Widget child;
  final ValueChanged<int> onTap;

  const _Choice({
    required this.value,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedScale(
        scale: selected ? 1.08 : 0.94,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Opacity(opacity: selected ? 1 : 0.55, child: child),
      ),
    );
  }
}
