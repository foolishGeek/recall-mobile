// Recall · custom share / save marks for the summary sheet. Thin geometric
// strokes — not Material's stock ios_share / download. Soft pill hit targets
// so they read as intentional UI, not 90s toolbar chrome.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

/// Soft circular action used next to the Summary title.
class SummarySheetAction extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;

  const SummarySheetAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.grey300,
              shape: BoxShape.circle,
              border: Border.all(color: c.grey200),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

/// Paper plane — the universal "send this out" mark.
class ShareMarkIcon extends StatelessWidget {
  final Color color;
  final double size;

  const ShareMarkIcon({super.key, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShareMarkPainter(color)),
    );
  }
}

/// Arrow settling into a tray — "keep this."
class SaveMarkIcon extends StatelessWidget {
  final Color color;
  final double size;

  const SaveMarkIcon({super.key, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SaveMarkPainter(color)),
    );
  }
}

class _ShareMarkPainter extends CustomPainter {
  final Color color;
  _ShareMarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Share-nodes glyph, but the nodes are Recall's "falling seed" dots: one
    // source (left) sending to two destinations (right). Reads as share, on-brand.
    final source = Offset(s * 0.26, s * 0.50);
    final upper = Offset(s * 0.74, s * 0.24);
    final lower = Offset(s * 0.74, s * 0.76);

    final link = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(source, upper, link);
    canvas.drawLine(source, lower, link);

    final dot = Paint()..color = color;
    // Source is the biggest seed; destinations echo the fading dots of the mark.
    canvas.drawCircle(source, s * 0.135, dot);
    canvas.drawCircle(upper, s * 0.11, dot);
    canvas.drawCircle(lower, s * 0.11, dot);
  }

  @override
  bool shouldRepaint(covariant _ShareMarkPainter old) => old.color != color;
}

class _SaveMarkPainter extends CustomPainter {
  final Color color;
  _SaveMarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Tray.
    final tray = Path()
      ..moveTo(s * 0.18, s * 0.58)
      ..lineTo(s * 0.18, s * 0.78)
      ..quadraticBezierTo(s * 0.18, s * 0.86, s * 0.28, s * 0.86)
      ..lineTo(s * 0.72, s * 0.86)
      ..quadraticBezierTo(s * 0.82, s * 0.86, s * 0.82, s * 0.78)
      ..lineTo(s * 0.82, s * 0.58);
    canvas.drawPath(tray, stroke);

    // Arrow down into the tray.
    final arrow = Path()
      ..moveTo(s * 0.50, s * 0.16)
      ..lineTo(s * 0.50, s * 0.68)
      ..moveTo(s * 0.34, s * 0.52)
      ..lineTo(s * 0.50, s * 0.68)
      ..lineTo(s * 0.66, s * 0.52);
    canvas.drawPath(arrow, stroke);
  }

  @override
  bool shouldRepaint(covariant _SaveMarkPainter old) => old.color != color;
}
