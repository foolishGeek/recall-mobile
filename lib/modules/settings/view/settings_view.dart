// Recall · Settings screen (docs/12_settings.md). Six schema-backed section
// cards over a sticky mono top bar. UI only — every row delegates to
// SettingsController; destructive actions are red ink, not chips.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/mono_label.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/settings_controller.dart';
import 'widgets/settings_account_sheets.dart';
import 'widgets/settings_pref_sheets.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_subscription_card.dart';
import 'widgets/settings_theme_row.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return RecallScaffold.bare(
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.maybePop(context)),
          Expanded(
            child: Obx(
              () => RecallStateView(
                state: controller.viewState,
                errorMessage: controller.errorMessage,
                onRetry: controller.reload,
                child: _Body(c: c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.chevron_left, color: c.ink, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
        const Spacer(),
        const MonoLabel('Settings', size: 11, tracking: 0.16),
        const Spacer(),
        const SizedBox(width: 32),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  final RecallColors c;
  const _Body({required this.c});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
          child: Text(
            'Settings',
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.72,
              color: c.ink,
            ),
          ),
        ),
        Obx(() => _sections(context, controller)),
        const SizedBox(height: 18),
        Obx(() => Center(
              child: Text(
                'Recall · ${controller.appVersion.value ?? '—'}',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: c.grey400, letterSpacing: 0.6),
              ),
            )),
      ]),
    );
  }
}

// Built inside the parent Obx so every profile-derived label/toggle is tracked
// (Obx records only the observables read synchronously within its closure).
Widget _sections(BuildContext context, SettingsController controller) {
  final c = RecallColors.of(context);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Recall Drop ──────────────────────────────────────────────────────
      SettingsSection(label: 'Recall Drop', children: [
        ListRow(
          title: 'Notifications',
          subtitle: 'Ping me when a fresh set is ready',
          trailing: RecallToggle(
            value: controller.pushOptIn,
            onChanged: controller.togglePush,
          ),
        ),
        ListRow(
          title: 'Reminder style',
          subtitle: controller.frequencyLabel,
          onTap: () => showFrequencySheet(
            context,
            current: controller.dropFrequency,
            onSelected: controller.setDropFrequency,
          ),
        ),
        ListRow(
          title: 'Quiet hours',
          subtitle: controller.quietHoursLabel,
          onTap: () => showQuietHoursSheet(
            context,
            start: controller.quietHoursStart,
            end: controller.quietHoursEnd,
            onChanged: controller.setQuietHours,
          ),
        ),
        ListRow(
          title: 'Haptics on drop',
          trailing: RecallToggle(
            value: controller.hapticsOnDrop,
            onChanged: controller.toggleHaptics,
          ),
          divider: false,
        ),
      ]),

      // ── Review ───────────────────────────────────────────────────────────
      SettingsSection(label: 'Review', children: [
        ListRow(
          title: 'Memory strength',
          subtitle: controller.memoryStrengthLabel,
          onTap: () => showMemoryStrengthSheet(
            context,
            current: controller.memoryStrength,
            onSelected: controller.setMemoryStrength,
          ),
        ),
        ListRow(
          title: 'Default cooling period',
          subtitle: controller.coolingLabel,
          onTap: () => showCoolingSheet(
            context,
            currentDays: controller.coolingDays,
            onSelected: controller.setCoolingDays,
          ),
        ),
        ListRow(
          title: 'Daily review limit',
          subtitle: controller.dailyLimitLabel,
          divider: false,
          onTap: () => showDailyLimitSheet(
            context,
            current: controller.sessionSizeOverride,
            isPremium: controller.isPremium,
            onSelected: controller.setDailyLimit,
          ),
        ),
      ]),

      // ── Appearance ───────────────────────────────────────────────────────
      SettingsSection(label: 'Appearance', children: [
        SettingsThemeRow(
          value: controller.theme,
          onChanged: controller.setTheme,
        ),
      ]),

      // ── Account ──────────────────────────────────────────────────────────
      SettingsSection(label: 'Account', children: [
        _ExportRow(controller: controller),
        ListRow(
          title: 'Sign out',
          onTap: () => showSignOutSheet(context, onConfirm: controller.onSignOut),
        ),
        ListRow(
          title: 'Delete account',
          titleColor: c.chipRed,
          divider: false,
          onTap: () =>
              showDeleteAccountSheet(context, onConfirm: controller.onDeleteAccount),
        ),
      ]),

      // ── Subscription ─────────────────────────────────────────────────────
      SettingsSubscriptionCard(controller: controller),

      // ── Data & privacy ───────────────────────────────────────────────────
      SettingsSection(label: 'Data & privacy', children: [
        ListRow(
          title: 'Privacy policy',
          trailing: Icon(Icons.north_east, size: 14, color: c.grey400),
          onTap: controller.onOpenPrivacy,
        ),
        ListRow(
          title: 'Terms of service',
          trailing: Icon(Icons.north_east, size: 14, color: c.grey400),
          onTap: controller.onOpenTerms,
        ),
        ListRow(
          title: 'Analytics',
          subtitle: 'Anonymous · helps us improve',
          trailing: RecallToggle(
            value: controller.analyticsOptIn,
            onChanged: controller.toggleAnalytics,
          ),
          divider: false,
        ),
      ]),

      // Quiet, transient line for pref / IO errors.
      Obx(() {
        final msg = controller.notice.value;
        if (msg == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14, left: 10),
          child: Text(
            msg,
            style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600),
          ),
        );
      }),
    ]);
}

class _ExportRow extends StatelessWidget {
  final SettingsController controller;
  const _ExportRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Obx(() {
      if (controller.exporting.value) {
        return ListRow(
          title: 'Export data',
          subtitle: 'Preparing your export…',
          trailing: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.grey400),
          ),
        );
      }
      final exportErr = controller.exportError.value;
      if (exportErr != null) {
        return ListRow(
          title: 'Export data',
          subtitle: exportErr,
          onTap: controller.onExport,
        );
      }
      if (controller.isOffline) {
        return ListRow(
          title: 'Export data',
          subtitle: 'Unavailable offline',
          trailing: const SizedBox.shrink(),
        );
      }
      final status = controller.exportStatus.value;
      if (status?.hasFile == true) {
        return ListRow(
          title: 'Export data',
          subtitle: _readyLabel(status!),
          trailing: Icon(Icons.ios_share, size: 16, color: c.grey400),
          onTap: controller.onShareExport,
        );
      }
      return ListRow(title: 'Export data', onTap: controller.onExport);
    });
  }

  String _readyLabel(status) {
    final exp = status.fileExpiresAt as DateTime?;
    if (exp == null) return 'Ready to share';
    final hrs = exp.toUtc().difference(DateTime.now().toUtc()).inHours;
    if (hrs <= 0) return 'Ready to share';
    return 'Ready · expires in ${hrs}h';
  }
}
