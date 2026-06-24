// Recall · SoftCard. The base surface — 20px radius, 1px hairline, low diffuse shadow.
// Use everywhere instead of a raw Container so cards stay consistent.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_shape.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool elevated; // true = hero shadow
  final bool sunken; // dimmed "locked" surface
  final Color? background;
  final Border? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = RecallShape.radiusLg,
    this.elevated = false,
    this.sunken = false,
    this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = Colors.black.withValues(alpha: dark ? 0.3 : 0.04);
    final heroShadow = Colors.black.withValues(alpha: dark ? 0.4 : 0.05);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? (sunken ? c.cardSunken : c.card),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: c.grey200, width: 1),
        boxShadow: [
          BoxShadow(
            color: elevated ? heroShadow : shadowColor,
            offset: Offset(0, elevated ? 8 : 6),
            blurRadius: elevated ? 22 : 16,
          ),
        ],
      ),
      child: child,
    );
  }
}
