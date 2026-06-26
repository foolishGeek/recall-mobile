// Paywall "Buy AI credits" — premium-only consumable packs (ai_credits_100 /
// ai_credits_500). Live prices from the store; current balance from
// `profiles.ai_credit_balance` [D-UI-1]. Credits require active premium [D-PAY-2].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../controller/paywall_controller.dart';

class PaywallCreditsCard extends StatelessWidget {
  final PaywallController controller;
  const PaywallCreditsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Obx(() {
      final p100 = controller.credits100;
      final p500 = controller.credits500;
      if (p100 == null && p500 == null) return const SizedBox.shrink();
      return SoftCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MonoLabel('Buy AI credits'),
                const Spacer(),
                Icon(Icons.bolt_outlined, size: 14, color: c.grey500),
                const SizedBox(width: 4),
                MonoLabel(
                  '${controller.creditBalance} left',
                  color: c.grey500,
                  size: 9.5,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (p100 != null)
              _CreditRow(
                product: p100,
                count: '100 credits',
                busy: controller.busy.value,
                onBuy: () => controller.onBuyCredits(p100),
              ),
            if (p500 != null)
              _CreditRow(
                product: p500,
                count: '500 credits',
                busy: controller.busy.value,
                onBuy: () => controller.onBuyCredits(p500),
              ),
          ],
        ),
      );
    });
  }
}

class _CreditRow extends StatelessWidget {
  final StoreProduct product;
  final String count;
  final bool busy;
  final VoidCallback onBuy;

  const _CreditRow({
    required this.product,
    required this.count,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
          Opacity(
            opacity: busy ? 0.4 : 1,
            child: GestureDetector(
              onTap: busy ? null : onBuy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.priceString,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.inkOnInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
