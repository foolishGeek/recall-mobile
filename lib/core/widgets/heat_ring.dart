// Recall · HeatRing. A monochrome ring whose stroke weight, opacity, and halo
// all encode "heat" (how hot/overdue a card is). Used in Buckets, Insights mastery.
//
//   HeatRing(progress: 0.78, size: 54)
//
// `heat` 0..1 controls visual density:
//   0.0 → hairline (1.5px), low opacity, no halo  (cool / mastered)
//   1.0 → 4px stroke, full ink, soft grey halo    (hot / overdue)
//
// `progress` 0..1 is what the ring draws.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

class HeatRing extends StatelessWidget {
  final double progress;
  final double heat; // 0..1
  final double size;
  final String? center; // small text in the middle (e.g. "78")
  final TextStyle? centerStyle;

  const HeatRing({
    super.key,
    required this.progress,
    this.heat = 0.6,
    this.size = 54,
    this.center,
    this.centerStyle,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeatRingPainter(
          progress: progress.clamp(0, 1),
          heat: heat.clamp(0, 1),
          ink: c.ink,
          track: c.grey300,
        ),
        child: center == null
            ? null
            : Center(
                child: Text(
                  center!,
                  style: centerStyle ?? TextStyle(fontSize: 12, color: c.ink),
                ),
              ),
      ),
    );
  }
}

class _HeatRingPainter extends CustomPainter {
  final double progress, heat;
  final Color ink, track;
  _HeatRingPainter({
    required this.progress,
    required this.heat,
    required this.ink,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width / 2) - 5;
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = 1.5 + (4 - 1.5) * heat;
    final inkOpacity = 0.4 + (1.0 - 0.4) * heat;

    // Soft halo (only at higher heat)
    if (heat > 0.5) {
      final halo = Paint()
        ..color = ink.withValues(alpha: 0.10 + 0.10 * (heat - 0.5) * 2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, r, halo);
    }

    // Track
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Ring
    final ring = Paint()
      ..color = ink.withValues(alpha: inkOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, ring);
  }

  @override
  bool shouldRepaint(covariant _HeatRingPainter old) =>
      old.progress != progress || old.heat != heat || old.ink != ink;
}
