import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';

/// A single restrained, monochrome confetti puff — 18 ink strokes spray up over
/// 1.2s (easeOut) then fade 240ms. High-score only; never coloured, no sparkle.
class QuizConfetti extends StatefulWidget {
  final double width;
  final double height;
  const QuizConfetti({super.key, this.width = 260, this.height = 96});

  @override
  State<QuizConfetti> createState() => _QuizConfettiState();
}

class _QuizConfettiState extends State<QuizConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1440), // 1.2s spray + 240ms fade
  );

  static const double _sprayFraction = 1200 / 1440;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = RecallColors.of(context).ink;
    return IgnorePointer(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(t: _controller.value, ink: ink),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final Color ink;
  _ConfettiPainter({required this.t, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final spray = Curves.easeOut.transform(
      (t / _QuizConfettiState._sprayFraction).clamp(0.0, 1.0),
    );
    final fade = t <= _QuizConfettiState._sprayFraction
        ? 1.0
        : (1.0 - (t - _QuizConfettiState._sprayFraction) /
                (1 - _QuizConfettiState._sprayFraction))
            .clamp(0.0, 1.0);
    if (fade <= 0) return;

    final origin = Offset(size.width / 2, size.height);
    final stroke = Paint()
      ..color = ink.withValues(alpha: 0.55 * fade)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = ink.withValues(alpha: 0.65 * fade);

    const count = 18;
    final maxRadius = size.width * 0.46;
    for (var i = 0; i < count; i++) {
      // Fan upward: angles spread across the top half, deterministic per index.
      final spread = (i / (count - 1)) - 0.5; // -0.5..0.5
      final angle = -math.pi / 2 + spread * (math.pi * 0.92);
      final wobble = math.sin(i * 1.7) * 0.18;
      final reach = maxRadius * (0.55 + 0.45 * ((i * 37) % 100) / 100);
      final r = reach * spray;
      final dir = Offset(math.cos(angle + wobble), math.sin(angle + wobble));
      final base = origin + dir * (r * 0.72);
      final tip = origin + dir * r;

      if (i.isEven) {
        canvas.drawLine(base, tip, stroke);
      } else {
        canvas.drawCircle(tip, 2.0, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.ink != ink;
}
