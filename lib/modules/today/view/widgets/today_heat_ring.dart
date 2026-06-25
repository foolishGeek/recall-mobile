import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

class TodayHeatRing extends StatelessWidget {
  final int dueCount;
  final double progress;
  final double heat;
  final double haloOpacity;

  const TodayHeatRing({
    super.key,
    required this.dueCount,
    required this.progress,
    required this.heat,
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
          heat: heat.clamp(0, 1),
          haloOpacity: haloOpacity.clamp(0, 1),
          ink: c.ink,
          track: isDark ? c.grey300 : c.grey200,
          isDark: isDark,
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
              const MonoLabel('Cards due today', size: 10, tracking: 0.22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRingPainter extends CustomPainter {
  final double progress;
  final double heat;
  final double haloOpacity;
  final Color ink;
  final Color track;
  final bool isDark;

  _TodayRingPainter({
    required this.progress,
    required this.heat,
    required this.haloOpacity,
    required this.ink,
    required this.track,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 17;
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 10 + 10 * heat;
    final rect = Rect.fromCircle(center: center, radius: r);

    if (heat > 0.4 && haloOpacity > 0 && progress > 0) {
      final haloColor = isDark
          ? const Color(0xFFBEBECD).withValues(alpha: 0.28 * heat * haloOpacity)
          : ink.withValues(alpha: 0.24 * heat * haloOpacity);
      final haloPaint = Paint()
        ..color = haloColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isDark ? 14 : 13,
        );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        haloPaint,
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    if (progress > 0) {
      final inkOpacity = 0.4 + (1.0 - 0.4) * heat;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ink.withValues(alpha: inkOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TodayRingPainter old) =>
      old.progress != progress ||
      old.heat != heat ||
      old.haloOpacity != haloOpacity ||
      old.ink != ink ||
      old.track != track ||
      old.isDark != isDark;
}
