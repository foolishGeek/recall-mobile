// Paywall pricing card — live store price (selected plan) + Monthly/Yearly
// segmented tiles. Prices come from RevenueCat `storeProduct.priceString`; never
// hard-coded. Store unreachable → "Price unavailable — try again".

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../controller/paywall_controller.dart';

class PaywallPricingCard extends StatelessWidget {
  final PaywallController controller;
  const PaywallPricingCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Obx(() {
        if (!controller.hasPricing) return _Unavailable(c: c);
        final yearly = controller.yearlySelected.value;
        final price = yearly
            ? controller.yearlyPriceString
            : controller.monthlyPriceString;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: RecallMotion.easeOut,
                    child: Row(
                      key: ValueKey(price),
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            price ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                              fontSize: 36,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              letterSpacing: -0.72,
                              color: c.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          yearly ? '/ year' : '/ month',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            color: c.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'price set by store · cancel anytime',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: c.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PlanTiles(controller: controller, c: c),
          ],
        );
      }),
    );
  }
}

class _PlanTiles extends StatelessWidget {
  final PaywallController controller;
  final RecallColors c;
  const _PlanTiles({required this.controller, required this.c});

  @override
  Widget build(BuildContext context) {
    final yearly = controller.yearlySelected.value;
    return Column(
      children: [
        _Tile(
          label: 'Monthly',
          selected: !yearly,
          c: c,
          onTap: () => controller.toggleYearly(false),
        ),
        const SizedBox(height: 6),
        _Tile(
          label: 'Yearly −20%',
          selected: yearly,
          c: c,
          onTap: () => controller.toggleYearly(true),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final bool selected;
  final RecallColors c;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: RecallMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.cardSunken,
          border: Border.all(color: selected ? c.ink : c.grey200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: selected ? c.inkOnInk : c.grey600,
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final RecallColors c;
  const _Unavailable({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 16, color: c.grey500),
        const SizedBox(width: 10),
        Expanded(
          child: MonoLabel(
            'Price unavailable — try again',
            color: c.grey500,
            size: 11,
            tracking: 0.1,
          ),
        ),
      ],
    );
  }
}
