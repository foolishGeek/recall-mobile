import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/models.dart';

/// One per-question row: an ink check coin (correct) or hollow cross coin
/// (incorrect). Incorrect rows expand inline to show the user's answer
/// (Fraunces italic, muted) and the right answer (Inter, bold) — never coloured.
class QuizBreakdownRow extends StatelessWidget {
  final int index;
  final QuizResultQuestion question;

  const QuizBreakdownRow({
    super.key,
    required this.index,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final correct = question.isCorrect;
    final wrote = question.userAnswer?.trim() ?? '';
    final right = question.correctAnswer?.trim() ?? '';
    final feedback = question.aiFeedback?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Coin(correct: correct),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Q${index.toString().padLeft(2, '0')}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        color: c.grey500,
                      ),
                    ),
                    if (question.nodeTitle != null &&
                        question.nodeTitle!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '— ${question.nodeTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: c.grey400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  question.prompt,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.5,
                    color: c.ink,
                  ),
                ),
                if (!correct && (wrote.isNotEmpty || right.isNotEmpty))
                  _AnswerBlock(wrote: wrote, right: right),
                if (!correct && feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    feedback,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: c.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  final bool correct;
  const _Coin({required this.correct});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: correct ? c.ink : c.card,
        border: correct ? null : Border.all(color: c.ink, width: 1.5),
      ),
      child: Icon(
        correct ? Icons.check : Icons.close,
        size: correct ? 14 : 12,
        color: correct ? c.inkOnInk : c.ink,
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  final String wrote;
  final String right;
  const _AnswerBlock({required this.wrote, required this.right});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wrote.isNotEmpty) ...[
            _label('You wrote', c),
            const SizedBox(height: 4),
            Text(
              '"$wrote"',
              style: GoogleFonts.fraunces(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: c.grey600,
              ),
            ),
          ],
          if (wrote.isNotEmpty && right.isNotEmpty)
            Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: c.grey200),
          if (right.isNotEmpty) ...[
            _label('Right', c),
            const SizedBox(height: 4),
            Text(
              right,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: c.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text, RecallColors c) => Text(
        text.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          letterSpacing: 1.7,
          color: c.grey500,
        ),
      );
}
