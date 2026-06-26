// Recall · You upgrade hero (free / downgraded). A single calm ink card where
// the premium memory-simulation curve would live — the editorial promise, a
// small ghost curve, and one "Unlock simulation" button. No nag, no modal.
// Shows no live numbers (retention is premium-only on the backend).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class YouUpgradeHero extends StatelessWidget {
  final VoidCallback onUnlock;
  const YouUpgradeHero({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      elevated: true,
      radius: 24,
      background: c.ink,
      border: Border.all(color: c.ink),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Memory simulation', size: 10, tracking: 0.2, color: c.grey400),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.18,
                letterSpacing: -0.24,
                color: c.inkOnInk,
              ),
              children: const [
                TextSpan(text: "See how much you'd remember "),
                TextSpan(
                  text: 'with',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: " Recall — and how little without it."),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _GhostCurvePainter(paper: c.inkOnInk, grey: c.grey400),
            ),
          ),
          const SizedBox(height: 14),
          _UnlockButton(onTap: onUnlock),
        ],
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UnlockButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: c.inkOnInk,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unlock simulation',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two smooth ghost beziers on the ink card: solid "with", dashed "without".
class _GhostCurvePainter extends CustomPainter {
  final Color paper, grey;
  _GhostCurvePainter({required this.paper, required this.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final solid = Paint()
      ..color = paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dashed = Paint()
      ..color = grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final without = Path()
      ..moveTo(0, h * 0.13)
      ..cubicTo(w * 0.14, h * 0.20, w * 0.36, h * 0.60, w * 0.64, h * 0.80)
      ..cubicTo(w * 0.86, h * 0.93, w, h * 0.93, w, h * 0.93);
    final withRecall = Path()
      ..moveTo(0, h * 0.13)
      ..cubicTo(w * 0.21, h * 0.17, w * 0.50, h * 0.23, w * 0.78, h * 0.30)
      ..cubicTo(w * 0.92, h * 0.34, w, h * 0.36, w, h * 0.36);

    for (final metric in without.computeMetrics()) {
      var dist = 0.0;
      const dash = 4.0, gap = 4.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, (dist + dash).clamp(0, metric.length)),
          dashed,
        );
        dist += dash + gap;
      }
    }
    canvas.drawPath(withRecall, solid);
  }

  @override
  bool shouldRepaint(covariant _GhostCurvePainter old) =>
      old.paper != paper || old.grey != grey;
}
