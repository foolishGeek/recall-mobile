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
import '../theme/recall_motion.dart';

class HeatRing extends StatelessWidget {
  final double progress;
  final double heat; // 0..1
  final double size;
  final double inset;
  final double? trackWidth;
  final double? ringWidth;
  final String? center; // small text in the middle (e.g. "78")
  final TextStyle? centerStyle;
  final Widget? centerWidget;

  const HeatRing({
    super.key,
    required this.progress,
    this.heat = 0.6,
    this.size = 54,
    this.inset = 5,
    this.trackWidth,
    this.ringWidth,
    this.center,
    this.centerStyle,
    this.centerWidget,
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
          track: c.grey200,
          inset: inset,
          trackWidth: trackWidth,
          ringWidth: ringWidth,
        ),
        child: centerWidget ??
            (center == null
                ? null
                : Center(
                    child: Text(
                      center!,
                      style:
                          centerStyle ?? TextStyle(fontSize: 12, color: c.ink),
                    ),
                  )),
      ),
    );
  }
}

/// A [HeatRing] that draws its arc in once on first build (600ms easeInOut per
/// Insights mastery motion). Honors reduced motion (snaps to full). The center
/// label and heat density are passed straight through.
class AnimatedHeatRing extends StatelessWidget {
  final double progress;
  final double heat;
  final double size;
  final String? center;
  final TextStyle? centerStyle;
  final Duration duration;

  /// Explicit stroke weights (e.g. the You-tab XP ring's flat 5px full-ink
  /// look). When set, the ring paints at full opacity with no heat halo.
  final double? trackWidth;
  final double? ringWidth;

  const AnimatedHeatRing({
    super.key,
    required this.progress,
    this.heat = 0.6,
    this.size = 54,
    this.center,
    this.centerStyle,
    this.duration = const Duration(milliseconds: 600),
    this.trackWidth,
    this.ringWidth,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? target : 0.0, end: target),
      duration: reduceMotion ? Duration.zero : duration,
      curve: RecallMotion.easeInOut,
      builder: (context, value, _) => HeatRing(
        progress: value,
        heat: heat,
        size: size,
        center: center,
        centerStyle: centerStyle,
        trackWidth: trackWidth,
        ringWidth: ringWidth,
      ),
    );
  }
}

class _HeatRingPainter extends CustomPainter {
  final double progress, heat;
  final Color ink, track;
  final double inset;
  final double? trackWidth;
  final double? ringWidth;
  _HeatRingPainter({
    required this.progress,
    required this.heat,
    required this.ink,
    required this.track,
    required this.inset,
    this.trackWidth,
    this.ringWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width / 2) - inset;
    final center = Offset(size.width / 2, size.height / 2);
    // Stroke weight scales with heat: 2.5px (cool / hairline) → 5px (hot).
    final autoStroke = 2.5 + (5 - 2.5) * heat;
    final tWidth = trackWidth ?? autoStroke;
    final rWidth = ringWidth ?? autoStroke;
    final inkOpacity = trackWidth != null ? 1.0 : 0.45 + (1.0 - 0.45) * heat;

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
        ..strokeWidth = tWidth,
    );

    // Ring
    final ring = Paint()
      ..color = ink.withValues(alpha: inkOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, ring);
  }

  @override
  bool shouldRepaint(covariant _HeatRingPainter old) =>
      old.progress != progress ||
      old.heat != heat ||
      old.ink != ink ||
      old.inset != inset ||
      old.trackWidth != trackWidth ||
      old.ringWidth != ringWidth;
}
