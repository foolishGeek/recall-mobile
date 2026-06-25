import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

class RecentQuizChip extends StatelessWidget {
  final String label;

  const RecentQuizChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.cardSunken,
        border: Border.all(color: c.grey200),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: t.monoCaption.copyWith(
          color: c.grey600,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
