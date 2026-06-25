import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

/// Top bar: `× Done` (left) · mono `{BUCKET} · RESULTS` (center) · share (right).
class QuizResultsTopBar extends StatelessWidget {
  final String header;
  final VoidCallback onDone;
  final VoidCallback onShare;

  const QuizResultsTopBar({
    super.key,
    required this.header,
    required this.onDone,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDone,
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 16, color: c.grey600),
                  const SizedBox(width: 6),
                  Text(
                    'Done',
                    style: GoogleFonts.inter(fontSize: 13, color: c.grey600),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: MonoLabel(header, size: 11, tracking: 0.18, color: c.grey500),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onShare,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.ios_share, size: 18, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
