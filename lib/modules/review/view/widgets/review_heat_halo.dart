import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

class ReviewHeatHalo extends StatelessWidget {
  final double heat;

  const ReviewHeatHalo({super.key, required this.heat});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = 340.0 + (heat.clamp(0.0, 1.0) * 40.0);
    final opacity = heat.clamp(0.0, 1.0);

    final centerColor = dark
        ? Color.fromRGBO(220, 220, 235, opacity * 0.16)
        : c.ink.withValues(alpha: opacity * 0.13);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.08),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [centerColor, Colors.transparent],
                stops: const [0.0, 0.65],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
