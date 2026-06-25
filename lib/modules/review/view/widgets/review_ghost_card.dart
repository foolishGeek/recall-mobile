import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

class ReviewGhostCard extends StatelessWidget {
  const ReviewGhostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 46,
      right: 46,
      top: 42,
      child: Opacity(
        opacity: 0.55,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.grey200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.04),
                offset: const Offset(0, 4),
                blurRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
