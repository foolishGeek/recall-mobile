// Recall · Subscription section. Tier-aware (free / premium / downgraded): plan
// chip + renews, Manage + Restore, and the premium "Buy AI credits" row showing
// the live balance [D-UI-1]. Free collapses to a single upgrade row; downgraded
// shows an expired card with frozen, read-only credits (docs/12_settings.md §8).
// While `limits_profile=relaxed`, hide upgrade/paywall chrome (config-driven).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/list_row.dart';
import '../../controller/settings_controller.dart';
import 'settings_account_sheets.dart';
import 'settings_section.dart';

class SettingsSubscriptionCard extends StatelessWidget {
  final SettingsController controller;
  const SettingsSubscriptionCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isPremium) return _premium(context);
      if (controller.suppressPaywall) return _relaxedFree(context);
      if (controller.isDowngraded) return _downgraded(context);
      return _free(context);
    });
  }

  // ── Premium: plan + renews + Manage + Restore + Buy AI credits ────────────
  Widget _premium(BuildContext context) {
    return SettingsSection(label: 'Subscription', children: [
      ListRow(
        title: 'Plan',
        subtitle: controller.renewsLabel,
        trailing: const _PlanChip(label: 'PREMIUM', solid: true),
      ),
      ListRow(
        title: 'Manage in store',
        trailing: _externalGlyph(context),
        onTap: controller.onManageStore,
      ),
      ListRow(title: 'Restore purchases', onTap: controller.onRestore),
      ListRow(
        title: 'Buy AI credits',
        subtitle: '${controller.creditBalance} credits',
        divider: false,
        onTap: () => showBuyCreditsSheet(context, controller: controller),
      ),
    ]);
  }

  // ── Temporary free (limits_profile=relaxed): plan only, no upgrade CTA ────
  Widget _relaxedFree(BuildContext context) {
    return SettingsSection(label: 'Subscription', children: [
      ListRow(
        title: 'Plan',
        subtitle: 'All features open for now',
        trailing: const _PlanChip(label: 'FREE', solid: false),
        divider: false,
      ),
    ]);
  }

  // ── Downgraded: expired card + upgrade + frozen, read-only credits ────────
  Widget _downgraded(BuildContext context) {
    final c = RecallColors.of(context);
    return SettingsSection(label: 'Subscription', children: [
      ListRow(
        title: 'Plan',
        subtitle: 'Subscription expired',
        trailing: const _PlanChip(label: 'EXPIRED', solid: false),
        onTap: controller.onUpgrade,
      ),
      ListRow(title: 'Restore purchases', onTap: controller.onRestore),
      ListRow(
        title: 'AI credits',
        subtitle: 'Frozen · ${controller.creditBalance} credits',
        divider: false,
        trailing: Icon(Icons.lock_outline, size: 15, color: c.grey400),
      ),
    ]);
  }

  // ── Free: collapsed plan → upgrade ────────────────────────────────────────
  Widget _free(BuildContext context) {
    return SettingsSection(label: 'Subscription', children: [
      ListRow(
        title: 'Plan',
        subtitle: 'Upgrade for full insights',
        trailing: const _PlanChip(label: 'FREE', solid: false),
        divider: false,
        onTap: controller.onUpgrade,
      ),
    ]);
  }

  Widget _externalGlyph(BuildContext context) =>
      Icon(Icons.north_east, size: 14, color: RecallColors.of(context).grey400);
}

class _PlanChip extends StatelessWidget {
  final String label;
  final bool solid;
  const _PlanChip({required this.label, required this.solid});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: solid ? c.ink : Colors.transparent,
        border: solid ? null : Border.all(color: c.grey400, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: solid ? c.inkOnInk : c.grey500,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}
