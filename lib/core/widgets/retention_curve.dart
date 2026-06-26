// Recall · RetentionCurve. The dual-line forgetting curve used on Insights and
// the You-tab Memory Simulation. Solid ink for "with Recall", dashed grey for
// "without". Two modes:
//   • data mode — pass server `points` (day-normalized, retention 0..1) and the
//     curve is drawn through real samples from `retention-simulate`.
//   • preview mode — no points → smooth bezier ghosts (locked free-tier tiles).
// `solidProgress` / `baselineProgress` (0..1) drive the draw-in animation; the
// `AnimatedRetentionCurve` wrapper choreographs them per the design timeline.

import 'package:flutter/material.dart';

import '../../data/models/retention_simulation.dart';
import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';

class RetentionCurve extends StatelessWidget {
  final double withRecall; // 0..1 — preview-mode solid end
  final double withoutRecall; // 0..1 — preview-mode dashed end
  final double height;
  final bool showGridlines;

  /// Real samples from `retention-simulate`. When non-empty, drawn instead of
  /// the preview beziers.
  final List<CurvePoint> points;

  /// Draw-in fractions (0..1). 1 = fully drawn (default/static).
  final double solidProgress;
  final double baselineProgress;

  const RetentionCurve({
    super.key,
    this.withRecall = 0.82,
    this.withoutRecall = 0.21,
    this.height = 110,
    this.showGridlines = true,
    this.points = const [],
    this.solidProgress = 1.0,
    this.baselineProgress = 1.0,
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
          points: points,
          solidProgress: solidProgress.clamp(0.0, 1.0),
          baselineProgress: baselineProgress.clamp(0.0, 1.0),
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
  final List<CurvePoint> points;
  final double solidProgress, baselineProgress;
  final Color ink, dashedInk, grid;
  final bool showGridlines;

  _CurvePainter({
    required this.withRecall,
    required this.withoutRecall,
    required this.points,
    required this.solidProgress,
    required this.baselineProgress,
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

    double yFor(double pct) => bottomY - (bottomY - topY) * pct.clamp(0.0, 1.0);

    final Path solid;
    final Path dashed;
    if (points.length > 1) {
      final maxDay = points.last.day == 0 ? 1 : points.last.day;
      solid = _seriesPath(points.map((p) => p.withRecall).toList(), maxDay, w, yFor);
      dashed = _seriesPath(points.map((p) => p.baseline).toList(), maxDay, w, yFor);
    } else {
      solid = _previewSolid(w, topY, bottomY, yFor);
      dashed = _previewDashed(w, topY, bottomY, yFor);
    }

    _drawProgress(canvas, dashed, baselineProgress, dashedInk, 1.6, dashedStroke: true);
    _drawProgress(canvas, solid, solidProgress, ink, 2.2, dashedStroke: false);

    _endDot(canvas, solid, solidProgress, ink, 3.6);
    _endDot(canvas, dashed, baselineProgress, dashedInk, 3.4);
  }

  Path _seriesPath(List<double> values, int maxDay, double w, double Function(double) yFor) {
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * w;
      final y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  Path _previewSolid(double w, double topY, double bottomY, double Function(double) yFor) {
    final yWith = yFor(withRecall);
    return Path()
      ..moveTo(0, topY)
      ..cubicTo(w * 0.22, topY + (yWith - topY) * 0.15, w * 0.45,
          topY + (yWith - topY) * 0.55, w * 0.70, yWith)
      ..cubicTo(w * 0.85, yWith + (yFor(withRecall * 0.95) - yWith) * 0.5, w * 0.95,
          yFor(withRecall * 0.93), w, yFor(withRecall * 0.92));
  }

  Path _previewDashed(double w, double topY, double bottomY, double Function(double) yFor) {
    final yWithout = yFor(withoutRecall);
    return Path()
      ..moveTo(0, topY)
      ..cubicTo(w * 0.12, topY + 10, w * 0.30, bottomY * 0.55, w * 0.56, yWithout - 10)
      ..cubicTo(w * 0.78, yWithout + 6, w * 0.92, bottomY - 6, w, bottomY);
  }

  /// Draws [path] up to [progress] of its length, optionally dashed.
  void _drawProgress(
    Canvas canvas,
    Path path,
    double progress,
    Color color,
    double strokeWidth, {
    required bool dashedStroke,
  }) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final end = metric.length * progress;
      final visible = metric.extractPath(0, end);
      if (dashedStroke) {
        _drawDashed(canvas, visible, paint);
      } else {
        canvas.drawPath(visible, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path source, Paint paint) {
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

  void _endDot(Canvas canvas, Path path, double progress, Color color, double r) {
    if (progress <= 0) return;
    for (final metric in path.computeMetrics()) {
      final tan = metric.getTangentForOffset(metric.length * progress);
      if (tan != null) {
        canvas.drawCircle(tan.position, r, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.withRecall != withRecall ||
      old.withoutRecall != withoutRecall ||
      old.points != points ||
      old.solidProgress != solidProgress ||
      old.baselineProgress != baselineProgress ||
      old.ink != ink;
}

/// Choreographs the curve draw-in. Default timeline (design 09_insights §Motion):
/// solid 700ms, dashed +120ms. Set [baselineFirst] for the peak-end "first
/// reveal" narrative: the dashed baseline (the loss) draws first, then the solid
/// "with Recall" line (the save) rises through it and settles bubbly. Honors
/// reduced motion (paints fully, instantly).
class AnimatedRetentionCurve extends StatefulWidget {
  final List<CurvePoint> points;
  final double withRecall;
  final double withoutRecall;
  final double height;
  final bool showGridlines;
  final bool baselineFirst;

  const AnimatedRetentionCurve({
    super.key,
    this.points = const [],
    this.withRecall = 0.82,
    this.withoutRecall = 0.21,
    this.height = 92,
    this.showGridlines = true,
    this.baselineFirst = false,
  });

  @override
  State<AnimatedRetentionCurve> createState() => _AnimatedRetentionCurveState();
}

class _AnimatedRetentionCurveState extends State<AnimatedRetentionCurve>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // 700ms primary line + 120ms follow delay = 820ms total.
  static const _total = 820;
  late final Animation<double> _solid;
  late final Animation<double> _dashed;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _total),
    );

    // The hero (solid) line uses bubbly on its tail when it leads the reveal.
    final lead = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 700 / _total, curve: RecallMotion.easeInOut),
    );
    final follow = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(120 / _total, 1.0,
          curve: widget.baselineFirst ? RecallMotion.bubbly : RecallMotion.easeInOut),
    );

    if (widget.baselineFirst) {
      _dashed = lead; // loss draws first
      _solid = follow; // save rises through, settling bubbly
    } else {
      _solid = lead;
      _dashed = follow;
    }

    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => RetentionCurve(
        points: widget.points,
        withRecall: widget.withRecall,
        withoutRecall: widget.withoutRecall,
        height: widget.height,
        showGridlines: widget.showGridlines,
        solidProgress: _solid.value,
        baselineProgress: _dashed.value,
      ),
    );
  }
}
