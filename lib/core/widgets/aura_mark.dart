// Recall · AuraMark — the single, minimalist animated AI mark used everywhere
// Aura appears (chat header, answer header, node Ask-AI bar, eval panel). A calm
// breathing 4-point sparkle with one slow orbiting dot, drawn in ink/grey only
// to respect the design system (no new colors). Reduced-motion safe: when
// animations are disabled it renders a still mark.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

class AuraMark extends StatefulWidget {
  final double size;

  /// Defaults to the resolved ink color. Pass to tint (e.g. on-ink surfaces).
  final Color? color;

  /// When false, the mark is static even if motion is allowed (e.g. dense lists).
  final bool animate;

  const AuraMark({super.key, this.size = 24, this.color, this.animate = true});

  @override
  State<AuraMark> createState() => _AuraMarkState();
}

class _AuraMarkState extends State<AuraMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the OS reduce-motion setting once we have a MediaQuery.
    if (_reduceMotion && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? RecallColors.of(context).ink;
    final still = !widget.animate || _reduceMotion;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _AuraPainter(
            t: still ? 0.18 : _c.value,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double t; // 0..1 progress
  final Color color;

  _AuraPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Breathing factor: calm ease-in-out between 0.9 and 1.0.
    final breathe = 0.9 + 0.1 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));

    // 4-point sparkle: a concave diamond drawn from the center.
    final starR = r * 0.62 * breathe;
    final waist = starR * 0.30;
    final path = Path()
      ..moveTo(center.dx, center.dy - starR)
      ..quadraticBezierTo(center.dx + waist, center.dy - waist,
          center.dx + starR, center.dy)
      ..quadraticBezierTo(center.dx + waist, center.dy + waist,
          center.dx, center.dy + starR)
      ..quadraticBezierTo(center.dx - waist, center.dy + waist,
          center.dx - starR, center.dy)
      ..quadraticBezierTo(center.dx - waist, center.dy - waist,
          center.dx, center.dy - starR)
      ..close();

    final fill = Paint()
      ..color = color.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fill);

    // One slow orbiting dot — a quiet sense of "thinking".
    final angle = t * 2 * math.pi;
    final orbitR = r * 0.86;
    final dot = Offset(
      center.dx + orbitR * math.cos(angle),
      center.dy + orbitR * math.sin(angle),
    );
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(dot, r * 0.12, dotPaint);
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.t != t || old.color != color;
}
