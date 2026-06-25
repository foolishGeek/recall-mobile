import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../controller/quiz_play_controller.dart';

/// Roomy italic-Fraunces textarea (the same italic used for prompt examples on
/// Quiz Config), a live char count, and the quiet "Plain English is fine." line.
class QuizShortAnswerField extends StatelessWidget {
  final TextEditingController controller;
  final int charCount;

  const QuizShortAnswerField({
    super.key,
    required this.controller,
    required this.charCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return CustomPaint(
      painter: _DashedBorderPainter(color: c.grey400, radius: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.canvas,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                minLines: null,
                maxLength: kQuizShortAnswerMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                cursorColor: c.ink,
                cursorWidth: 2,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.09,
                  color: c.ink,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Type your answer…',
                  hintStyle: GoogleFonts.fraunces(
                    fontSize: 18,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: c.grey500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: c.grey300),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLAIN ENGLISH IS FINE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 10 * 0.14,
                    color: c.grey500,
                  ),
                ),
                Text(
                  '$charCount chars',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 10 * 0.14,
                    color: c.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
