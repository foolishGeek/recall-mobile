// Recall · RetentionCurve. The dual-line forgetting curve used on Insights and
// the You-tab Memory Simulation. Solid ink for "with Recall", dashed grey for
// "without". Both lines are smooth, bezier-driven, and end-anchored with a dot.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

class RetentionCurve extends StatelessWidget {
  final double withRecall; // 0..1 — where the solid line ends
  final double withoutRecall; // 0..1 — where the dashed line ends
  final double height;
  final bool showGridlines;

  const RetentionCurve({
    super.key,
    this.withRecall = 0.82,
    this.withoutRecall = 0.21,
    this.height = 110,
    this.showGridlines = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CurvePainter(
          withRecall: withRecall,
          withoutRecall: withoutRecall,
          ink: c.ink,
          dashedInk: c.grey600,
          grid: c.grey300,
          showGridlines: showGridlines,
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final double withRecall, withoutRecall;
  final Color ink, dashedInk, grid;
  final bool showGridlines;
  _CurvePainter({
    required this.withRecall,
    required this.withoutRecall,
    required this.ink,
    required this.dashedInk,
    required this.grid,
    required this.showGridlines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final topY = h * 0.10;
    final bottomY = h * 0.95;

    if (showGridlines) {
      final g = Paint()
        ..color = grid
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, h * 0.20), Offset(w, h * 0.20), g);
      canvas.drawLine(Offset(0, h * 0.60), Offset(w, h * 0.60), g);
    }

    double yFor(double pct) => bottomY - (bottomY - topY) * pct;

    // Solid: with Recall
    final yWith = yFor(withRecall);
    final pathWith = Path()
      ..moveTo(0, topY)
      ..cubicTo(
        w * 0.22,
        topY + (yWith - topY) * 0.15,
        w * 0.45,
        topY + (yWith - topY) * 0.55,
        w * 0.70,
        yWith,
      )
      ..cubicTo(
        w * 0.85,
        yWith + (yFor(withRecall * 0.95) - yWith) * 0.5,
        w * 0.95,
        yFor(withRecall * 0.93),
        w,
        yFor(withRecall * 0.92),
      );
    canvas.drawPath(
      pathWith,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Dashed: without
    final yWithout = yFor(withoutRecall);
    final pathWithout = Path()
      ..moveTo(0, topY)
      ..cubicTo(w * 0.12, topY + 10, w * 0.30, h * 0.55, w * 0.56, yWithout - 10)
      ..cubicTo(w * 0.78, yWithout + 6, w * 0.92, bottomY - 6, w, bottomY);
    _drawDashed(canvas, pathWithout, dashedInk);

    // End dots
    canvas.drawCircle(
      Offset(w, yFor(withRecall * 0.92)),
      3.6,
      Paint()..color = ink,
    );
    canvas.drawCircle(Offset(w, bottomY), 3.4, Paint()..color = dashedInk);
  }

  void _drawDashed(Canvas canvas, Path source, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const dashLen = 4.0, gapLen = 4.0;
    for (final metric in source.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dashLen;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0, metric.length).toDouble()),
          paint,
        );
        dist = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.withRecall != withRecall ||
      old.withoutRecall != withoutRecall ||
      old.ink != ink;
}
