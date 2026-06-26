// Recall · You chrome. The top bar (mono "YOU" + tier badge) and the avatar /
// name / email row. Tier is conveyed by weight only — PREMIUM is a solid-ink
// pill, FREE a quiet outline pill (never color). Pure UI.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// Top bar: mono "YOU" left · PREMIUM (solid) / FREE (outline) badge right.
class YouTopBar extends StatelessWidget {
  final bool premium;
  const YouTopBar({super.key, required this.premium});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'YOU',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 11 * 0.16,
            color: c.grey500,
          ),
        ),
        _TierBadge(premium: premium),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  final bool premium;
  const _TierBadge({required this.premium});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: premium ? c.ink : c.canvas,
        borderRadius: BorderRadius.circular(7),
        border: premium ? null : Border.all(color: c.grey400, width: 1),
      ),
      child: Text(
        premium ? 'PREMIUM' : 'FREE',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 9.5 * 0.14,
          color: premium ? c.inkOnInk : c.grey600,
        ),
      ),
    );
  }
}

/// Avatar (Fraunces initial) + name (Fraunces 24) + mono email.
class YouIdentityRow extends StatelessWidget {
  final String initial;
  final String name;
  final String? email;
  const YouIdentityRow({
    super.key,
    required this.initial,
    required this.name,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.fraunces(
              fontSize: 23,
              fontWeight: FontWeight.w500,
              color: c.inkOnInk,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.24,
                  color: c.ink,
                ),
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  email!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: c.grey500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
