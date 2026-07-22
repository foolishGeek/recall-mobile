// Recall · RecallCoachTip. A compact, dismissible one-time explainer strip used
// for inline tutorials. Low-cortisol: no modal, no blocking — a calm hint the
// user can read and dismiss. Persist "seen" via LocalStore.markCoachSeen so it
// shows at most once. Uses screen space sparingly (single soft card, one line
// or two of muted copy).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../utils/recall_haptics.dart';

class RecallCoachTip extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onDismiss;

  const RecallCoachTip({
    super.key,
    required this.text,
    required this.onDismiss,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c.grey500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.35,
                color: c.grey600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              RecallHaptics.selection();
              onDismiss();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 15, color: c.grey500),
            ),
          ),
        ],
      ),
    );
  }
}
