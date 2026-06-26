// Paywall hero — RecallMark + Nunito wordmark (46) + solid PREMIUM chip +
// Instrument Serif italic promise. The italic line fades in on a short delay
// (driven by [italic]); the mark + wordmark + chip ride the [reveal] fade/lift.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/recall_mark.dart';

class PaywallHero extends StatelessWidget {
  final Animation<double> reveal;
  final Animation<double> italic;

  const PaywallHero({super.key, required this.reveal, required this.italic});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      children: [
        AnimatedBuilder(
          animation: reveal,
          builder: (_, child) => Opacity(
            opacity: reveal.value,
            child: Transform.translate(
              offset: Offset(0, 4 * (1 - reveal.value)),
              child: child,
            ),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: RecallMark(size: 38),
              ),
              const SizedBox(height: 14),
              Text(
                'Recall',
                style: GoogleFonts.nunito(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 0.18,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 10),
              _PremiumChip(c: c),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: italic,
          child: SizedBox(
            width: 280,
            child: Text(
              'All your memory, gently held —\nfor less than a coffee.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                height: 1.22,
                color: c.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final RecallColors c;
  const _PremiumChip({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'PREMIUM',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: c.inkOnInk,
          letterSpacing: 1.7,
        ),
      ),
    );
  }
}
