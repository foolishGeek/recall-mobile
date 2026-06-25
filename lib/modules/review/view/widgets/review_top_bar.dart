import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class ReviewTopBar extends StatelessWidget {
  final String bucketName;
  final int position;
  final int total;
  final VoidCallback onClose;

  const ReviewTopBar({
    super.key,
    required this.bucketName,
    required this.position,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPad + 14, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 16, color: c.grey600),
                  const SizedBox(width: 6),
                  Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${bucketName.toUpperCase()} \u00B7 REVIEW',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 11 * 0.18,
              color: c.grey500,
            ),
          ),
          Text(
            '${position.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
