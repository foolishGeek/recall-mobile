import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/soft_card.dart';

class QuizCountStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const QuizCountStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _RoundButton(icon: Icons.remove, onTap: onMinus),
          Expanded(
            child: Column(
              children: [
                Text('$value', style: t.numeralLg.copyWith(color: c.ink)),
                Text(
                  'QUESTIONS',
                  style: t.monoLabelSm.copyWith(color: c.grey500),
                ),
              ],
            ),
          ),
          _RoundButton(icon: Icons.add, filled: true, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? c.ink : c.cardSunken,
          border: Border.all(color: filled ? c.ink : c.grey200),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: filled ? c.inkOnInk : c.grey500),
      ),
    );
  }
}
