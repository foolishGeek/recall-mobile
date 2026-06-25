import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class BucketTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMore;

  const BucketTopBar({
    super.key,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 16, color: c.grey600),
                const SizedBox(width: 2),
                Text(
                  'Buckets',
                  style: GoogleFonts.inter(fontSize: 13, color: c.grey600),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onMore,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.more_horiz, size: 18, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
