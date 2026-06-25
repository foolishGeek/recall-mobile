import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// End · {bucket} · {type} · {nn / nn}. The numeric count lives here quietly.
class QuizPlayTopBar extends StatelessWidget {
  final String eyebrow;
  final int position;
  final int total;
  final VoidCallback onEnd;

  const QuizPlayTopBar({
    super.key,
    required this.eyebrow,
    required this.position,
    required this.total,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onEnd,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 16, color: c.grey600),
                  const SizedBox(width: 6),
                  Text('End', style: GoogleFonts.inter(fontSize: 13, color: c.grey600)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              eyebrow.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 11 * 0.18,
                color: c.grey500,
              ),
            ),
          ),
          Text(
            '${position.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
