// Recall · the loop-mark drawn natively in Flutter (CustomPainter) so it scales
// perfectly at any size. Also available as an SVG asset.
//
//   const RecallMark(size: 40)                  // ink in light, paper in dark
//   const RecallMark(size: 92, color: paper)    // explicit
//
// Use RecallWordmark for the full lockup.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';

class RecallMark extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const RecallMark({super.key, this.size = 40, this.color, this.strokeWidth = 7});

  @override
  Widget build(BuildContext context) {
    final c = color ?? RecallColors.of(context).ink;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(c, strokeWidth)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color ink;
  final double sw;
  _MarkPainter(this.ink, this.sw);

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0..100 → scale
    final s = size.width / 100.0;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Open ring (path d="M62.7 24.8 A30 30 0 1 1 37.3 24.8")
    final ring = Path()
      ..moveTo(62.7 * s, 24.8 * s)
      ..arcToPoint(
        Offset(37.3 * s, 24.8 * s),
        radius: Radius.circular(30 * s),
        largeArc: true,
        clockwise: true,
      );
    canvas.drawPath(ring, stroke);

    // Three dots: the falling seed
    final fill = Paint()..color = ink;
    canvas.drawCircle(Offset(50 * s, 21 * s), 6.5 * s, fill);
    canvas.drawCircle(
      Offset(50 * s, 11.5 * s),
      3.8 * s,
      fill..color = ink.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      Offset(50 * s, 4.5 * s),
      2.2 * s,
      fill..color = ink.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.ink != ink || old.sw != sw;
}

class RecallWordmark extends StatelessWidget {
  final double size; // mark size
  final Color? color;
  final bool stacked; // mark above wordmark (Splash / Paywall) vs inline

  const RecallWordmark({
    super.key,
    this.size = 38,
    this.color,
    this.stacked = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? RecallColors.of(context).ink;
    final mark = RecallMark(size: size, color: c);
    final word = Text(
      'Recall',
      style: GoogleFonts.nunito(
        fontSize: size * 1.21,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: 0.2,
        height: 1.0,
      ),
    );
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [mark, SizedBox(height: size * 0.36), word],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [mark, SizedBox(width: size * 0.32), word],
    );
  }
}
