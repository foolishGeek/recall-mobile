// Aura whisper strip — a quiet, dismissible tip in Today's action dock that
// surfaces notes Aura thinks are slipping. Flat chrome (not SoftCard) so it
// never reads as a fourth review card. AuraMark keeps breathing.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/aura_mark.dart';

class TodayRelearnCard extends StatelessWidget {
  final int count;
  final bool isStarting;
  final VoidCallback onStart;
  final VoidCallback onDismiss;

  const TodayRelearnCard({
    super.key,
    required this.count,
    required this.isStarting,
    required this.onStart,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final noun = count == 1 ? 'note is' : 'notes are';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.cardSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.grey200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.card,
              shape: BoxShape.circle,
              border: Border.all(color: c.grey200),
            ),
            child: const AuraMark(size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AURA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: c.grey500,
                    letterSpacing: 9.5 * 0.18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Re-learn weak skills',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count $noun slipping — ${AuraBrand.name} can run a quick '
                  'focused round.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: c.grey500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isStarting)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.grey500),
            )
          else ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onStart,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: c.inkOnInk),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: SizedBox(
                width: 28,
                height: 36,
                child: Icon(Icons.close_rounded, size: 16, color: c.grey400),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
