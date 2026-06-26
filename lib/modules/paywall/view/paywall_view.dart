// Paywall view (S23). Slide-up sheet (route transition) that earns the upgrade:
// monochrome hero, Free/Premium ledger, live store pricing, purchase + restore.
// Premium lands on the "You're on Premium" state + Buy AI credits. Store
// unreachable → disabled CTA. Pixel gate: Design/handover/handoff/.../paywall_screen.dart.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_motion.dart';
import '../../../core/widgets/recall_button.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/staggered_reveal.dart';
import '../controller/paywall_controller.dart';
import 'widgets/paywall_hero.dart';
import 'widgets/paywall_ledger.dart';
import 'widgets/paywall_premium_state.dart';
import 'widgets/paywall_pricing_card.dart';
import 'widgets/paywall_top_bar.dart';

class PaywallView extends GetView<PaywallController> {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
    return RecallScaffold.bare(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 8),
        child: Obx(
          () => RecallStateView(
            state: controller.viewState,
            child: _PaywallBody(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _PaywallBody extends StatefulWidget {
  final PaywallController controller;
  const _PaywallBody({required this.controller});

  @override
  State<_PaywallBody> createState() => _PaywallBodyState();
}

class _PaywallBodyState extends State<_PaywallBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  late final Animation<double> _hero;
  late final Animation<double> _italic;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hero = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0, 0.4, curve: RecallMotion.easeOut),
    );
    _italic = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.22, 0.5, curve: RecallMotion.easeOut),
    );

    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final hero = PaywallTopBarAndHero(
        controller: c,
        hero: _hero,
        italic: _italic,
      );
      if (c.isPremium) {
        return SingleChildScrollView(
          child: Column(
            children: [
              hero,
              const SizedBox(height: 20),
              PaywallPremiumState(controller: c),
              const SizedBox(height: 12),
            ],
          ),
        );
      }
      return _FreeLayout(controller: c, reveal: _reveal, hero: hero);
    });
  }
}

/// Top bar + hero, shared by both tier states.
class PaywallTopBarAndHero extends StatelessWidget {
  final PaywallController controller;
  final Animation<double> hero;
  final Animation<double> italic;

  const PaywallTopBarAndHero({
    super.key,
    required this.controller,
    required this.hero,
    required this.italic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaywallTopBar(onClose: controller.onCloseTapped),
        PaywallHero(reveal: hero, italic: italic),
      ],
    );
  }
}

class _FreeLayout extends StatelessWidget {
  final PaywallController controller;
  final AnimationController reveal;
  final Widget hero;

  const _FreeLayout({
    required this.controller,
    required this.reveal,
    required this.hero,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                hero,
                const SizedBox(height: 20),
                StaggeredReveal(
                  index: 1,
                  controller: reveal,
                  child: const PaywallLedger(),
                ),
                const SizedBox(height: 14),
                StaggeredReveal(
                  index: 2,
                  controller: reveal,
                  child: PaywallPricingCard(controller: controller),
                ),
              ],
            ),
          ),
        ),
        Obx(() {
          final canBuy = controller.hasPricing && !controller.busy.value;
          return Column(
            children: [
              Opacity(
                opacity: controller.hasPricing ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !canBuy,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Go Premium',
                      onPressed: canBuy ? controller.onPurchase : () {},
                    ),
                  ),
                ),
              ),
              TextLinkButton(
                label: 'Restore purchases',
                onPressed:
                    controller.busy.value ? null : controller.onRestore,
              ),
              _NoticeLine(msg: controller.notice.value, c: c),
            ],
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Auto-renews. Manage in your store.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              color: c.grey500,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NoticeLine extends StatelessWidget {
  final String? msg;
  final RecallColors c;
  const _NoticeLine({required this.msg, required this.c});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: RecallMotion.normal,
      child: msg == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(msg),
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                msg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600),
              ),
            ),
    );
  }
}
