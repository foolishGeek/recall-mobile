import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

class QuizHomeProBadge extends StatelessWidget {
  final bool active;

  const QuizHomeProBadge({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: active ? Colors.transparent : c.ink,
        border: Border.all(color: active ? c.grey300 : c.ink),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        active ? 'PRO - ACTIVE' : 'PRO',
        style: t.monoLabelSm.copyWith(
          color: active ? c.grey500 : c.inkOnInk,
          fontSize: 8.5,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
