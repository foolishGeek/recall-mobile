// Already-premium state — a single calm "You're on Premium · renews {date}"
// card (from `subscriptions.expires_at`), Manage in your store, and the
// premium-only Buy AI credits packs. No purchase CTAs.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../controller/paywall_controller.dart';
import 'paywall_credits_card.dart';

class PaywallPremiumState extends StatelessWidget {
  final PaywallController controller;
  const PaywallPremiumState({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          elevated: true,
          radius: 22,
          background: c.ink,
          border: Border.all(color: c.ink),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel('Your plan', size: 10, tracking: 0.2, color: c.grey400),
              const SizedBox(height: 10),
              Text(
                "You're on Premium",
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.12,
                  letterSpacing: -0.24,
                  color: c.inkOnInk,
                ),
              ),
              Obx(() {
                final label = controller.renewsLabel;
                if (label == null) return const SizedBox(height: 4);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: c.inkOnInk,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PaywallCreditsCard(controller: controller),
        const SizedBox(height: 4),
        _ManageRow(onTap: controller.onManageStore, c: c),
      ],
    );
  }
}

class _ManageRow extends StatelessWidget {
  final VoidCallback onTap;
  final RecallColors c;
  const _ManageRow({required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Manage in your store',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: c.grey600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_outward, size: 15, color: c.grey500),
          ],
        ),
      ),
    );
  }
}
