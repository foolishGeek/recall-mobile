import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class BucketFab extends StatelessWidget {
  final VoidCallback onTap;

  const BucketFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.18),
              offset: const Offset(0, 10),
              blurRadius: 22,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 20, color: c.inkOnInk),
            const SizedBox(width: 6),
            Text(
              'Node',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: c.inkOnInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
