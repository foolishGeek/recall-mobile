import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

/// 2px hairline at the very top — the only chrome. Fills smoothly as the user
/// advances; no percentage, no correct/incorrect count.
class QuizProgressBar extends StatelessWidget {
  final double progress;

  const QuizProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.grey300)),
          Align(
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedContainer(
                duration: RecallMotion.normal,
                curve: RecallMotion.easeOut,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
