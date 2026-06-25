import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

/// Flashcard answer area. Hidden until Reveal, then the back fades in above the
/// self-rate row.
class QuizFlashcardPanel extends StatelessWidget {
  final bool revealed;
  final String back;

  const QuizFlashcardPanel({
    super.key,
    required this.revealed,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.grey200),
      ),
      child: AnimatedSwitcher(
        duration: RecallMotion.normal,
        switchInCurve: RecallMotion.easeOut,
        child: revealed
            ? Column(
                key: const ValueKey('back'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ANSWER',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 10 * 0.18,
                      color: c.grey500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    back,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      height: 1.45,
                      color: c.ink,
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('hidden'),
                children: [
                  Icon(Icons.visibility_off_outlined, size: 16, color: c.grey400),
                  const SizedBox(width: 10),
                  Text(
                    'Answer hidden — tap Reveal',
                    style: GoogleFonts.inter(fontSize: 13, color: c.grey500),
                  ),
                ],
              ),
      ),
    );
  }
}
