import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

class OnboardingDots extends StatelessWidget {
  final int count;
  final int active;
  final ValueChanged<int> onDotTap;

  const OnboardingDots({
    super.key,
    required this.count,
    required this.active,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
          child: GestureDetector(
            onTap: () => onDotTap(i),
            child: AnimatedContainer(
              duration: RecallMotion.normal,
              curve: Curves.easeOut,
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? c.ink : c.grey400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
