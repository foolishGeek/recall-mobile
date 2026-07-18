import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';

/// Quiet destructive confirm for deleting a note. Mirrors the bucket delete
/// sheet so it feels native: grabber, serif title, calm subtitle, a single
/// red primary and a quiet Cancel. The red is the only sanctioned non-chip
/// color (destructive intent), matching bucket_more_menu.
void showNodeDeleteSheet({
  required BuildContext context,
  required VoidCallback onDelete,
}) {
  final c = RecallColors.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delete this note?',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This note will be removed. This can't be undone.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: c.grey600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  RecallHaptics.heavy();
                  Navigator.pop(ctx);
                  onDelete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.chipRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete note',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: c.grey600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
