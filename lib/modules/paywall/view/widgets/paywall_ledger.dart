// Paywall ledger — side-by-side FREE / PREMIUM benefit columns. Static benefit
// copy (entitlements match `subscriptions`); grey for free, ink for premium.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

const _freeLines = <String>[
  '2 buckets',
  '2 review stacks / month',
  'Daily Recall Drop',
  'Basic insights',
  'AI capture & chat',
];

const _premiumLines = <String>[
  'Unlimited buckets',
  'Unlimited review stacks',
  'Quiz mode',
  'Full insights & curves',
  'Memory simulation',
];

class PaywallLedger extends StatelessWidget {
  const PaywallLedger({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      elevated: true,
      radius: 22,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border(
                      right: BorderSide(color: c.grey200, width: 1),
                    ),
                  ),
                  child: _Column(
                    title: 'Always',
                    label: 'Free',
                    lines: _freeLines,
                    premium: false,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  decoration: BoxDecoration(color: c.cardSunken),
                  child: _Column(
                    title: 'Everything',
                    label: 'Premium',
                    lines: _premiumLines,
                    premium: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final String label;
  final List<String> lines;
  final bool premium;

  const _Column({
    required this.title,
    required this.label,
    required this.lines,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MonoLabel(label, color: premium ? c.ink : null),
            if (premium) ...[
              const Spacer(),
              Icon(Icons.star, size: 12, color: c.ink),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: c.ink,
            letterSpacing: -0.18,
          ),
        ),
        const SizedBox(height: 14),
        for (final t in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: premium ? 7 : 5,
                  height: premium ? 7 : 5,
                  margin: EdgeInsets.only(top: premium ? 5 : 6, right: 7),
                  decoration: BoxDecoration(
                    color: premium ? c.ink : c.grey600,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: premium ? FontWeight.w500 : FontWeight.w400,
                      color: premium ? c.ink : c.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
