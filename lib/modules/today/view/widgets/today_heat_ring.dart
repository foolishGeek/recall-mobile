import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

/// Today due hero ring — flat monochrome progress (no heat glow).
class TodayHeatRing extends StatelessWidget {
  final int dueCount;
  final double progress;
  final double heat;
  final double haloOpacity;

  const TodayHeatRing({
    super.key,
    required this.dueCount,
    required this.progress,
    this.heat = 0,
    this.haloOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 206,
      height: 206,
      child: CustomPaint(
        painter: _TodayRingPainter(
          progress: progress.clamp(0, 1),
          ink: c.ink,
          track: isDark ? c.grey300 : c.grey200,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dueCount',
                style: GoogleFonts.fraunces(
                  fontSize: 62,
                  fontWeight: FontWeight.w500,
                  color: c.ink,
                  height: 0.9,
                  letterSpacing: 62 * -0.02,
                ),
              ),
              const SizedBox(height: 8),
              const MonoLabel('Ready to review', size: 10, tracking: 0.22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRingPainter extends CustomPainter {
  final double progress;
  final Color ink;
  final Color track;

  _TodayRingPainter({
    required this.progress,
    required this.ink,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final r = size.width / 2 - 17;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TodayRingPainter old) =>
      old.progress != progress || old.ink != ink || old.track != track;
}
