import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

class BucketHeatBar extends StatelessWidget {
  final List<double> segments;

  const BucketHeatBar({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final count = segments.isEmpty ? 10 : segments.length;

    return Row(
      children: List.generate(count, (i) {
        if (segments.isNotEmpty) {
          final opacity = segments[i].clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: 0.1 + opacity * 0.9),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }
        // Fallback: gradient from dark to light
        final t = (count - 1 - i) / (count - 1).clamp(1, count);
        final color = Color.lerp(c.ink, c.grey300, t)!;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}
