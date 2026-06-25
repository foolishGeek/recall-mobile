import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import 'quiz_confetti.dart';

/// The only "hero": a monochrome score ring (draws in 900ms) with a counter
/// tween, a Fraunces headline that softens with the score, and a quiet caption.
/// The confetti puff rides above the ring on high scores only.
class QuizScoreHero extends StatelessWidget {
  final int score;
  final int correct;
  final int total;
  final String headline;
  final String caption;
  final bool celebrate;

  const QuizScoreHero({
    super.key,
    required this.score,
    required this.correct,
    required this.total,
    required this.headline,
    required this.caption,
    required this.celebrate,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 18),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (celebrate && !reduceMotion)
                  const Positioned(top: -34, left: -30, child: QuizConfetti()),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  curve: RecallMotion.easeInOut,
                  builder: (context, t, _) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _ScoreRingPainter(
                      progress: (score / 100) * t,
                      ink: c.ink,
                      track: c.grey200,
                    ),
                    child: Center(
                      child: _RingLabel(
                        value: (score * t).round(),
                        correct: correct,
                        total: total,
                        colors: c,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              height: 1.08,
              letterSpacing: -0.5,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: c.grey600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLabel extends StatelessWidget {
  final int value;
  final int correct;
  final int total;
  final RecallColors colors;
  const _RingLabel({
    required this.value,
    required this.correct,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: '$value',
            style: GoogleFonts.fraunces(
              fontSize: 62,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -1.5,
              color: colors.ink,
            ),
            children: [
              TextSpan(
                text: '%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: colors.grey500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$correct OF $total CORRECT',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 2,
            color: colors.grey500,
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color ink;
  final Color track;
  _ScoreRingPainter({required this.progress, required this.ink, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 86.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress || old.ink != ink || old.track != track;
}
