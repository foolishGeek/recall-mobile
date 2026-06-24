// Recall · HeatDot. The tiny mono dot used in lists (Weak topics, Bucket nodes,
// Today's card stack). Opacity = heat. Adds a soft halo at high heat.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

class HeatDot extends StatelessWidget {
  final double heat; // 0..1
  final double size;
  const HeatDot({super.key, required this.heat, this.size = 9});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final op = heat.clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: op),
        shape: BoxShape.circle,
        boxShadow: op > 0.85
            ? [BoxShadow(color: c.ink.withValues(alpha: 0.3), blurRadius: size * 0.8)]
            : null,
      ),
    );
  }
}

/// Heat-distribution bar: 10 segments fading dark → light.
class HeatDistribution extends StatelessWidget {
  final int segments;
  const HeatDistribution({super.key, this.segments = 10});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: List.generate(segments, (i) {
        // map 0..segments-1 to dark..light then reverse so left=cool, right=hot
        final t = (segments - 1 - i) / (segments - 1);
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
