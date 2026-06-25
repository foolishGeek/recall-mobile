import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

class ReviewProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const ReviewProgressDots({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dotWidth = total > 12 ? 18.0 : 24.0;

    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          Color color;
          if (i < current) {
            color = c.ink;
          } else if (i == current) {
            color = c.grey600.withValues(alpha: 0.6);
          } else {
            color = c.grey400;
          }

          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: Container(
              width: dotWidth,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
