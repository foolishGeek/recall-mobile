import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/recall_colors.dart';
import '../../../core/utils/drop_readiness.dart';
import '../../../core/utils/how_it_works_copy.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/cooling_period_selector.dart';
import '../../../core/widgets/how_it_works_sheet.dart';
import '../../../core/widgets/memory_strength_selector.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/soft_card.dart';
import '../../bucket/controller/bucket_controller.dart';
import '../../bucket/view/widgets/bucket_custom_cooling_dialog.dart';

/// Dedicated "Bucket config" surface: the three dials as a legible recipe, each
/// with its own "What is it?". Cooling is a per-bucket deferred lever; Memory
/// strength writes immediately; Reminder style is account-wide (read-only here,
/// deep-links to Settings). Reuses the live BucketController.
class BucketConfigView extends GetView<BucketController> {
  const BucketConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return RecallScaffold.bare(
      body: Column(
        children: [
          _Header(onDone: () => _onDone(context)),
          Expanded(
            child: Obx(() {
              final disabled =
                  controller.readOnly.value || !controller.bucketSrEnabled;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!controller.bucketSrEnabled) ...[
                      _RevisionOffNote(),
                      const SizedBox(height: 14),
                    ],
                    SoftCard(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: CoolingPeriodSelector(
                        activeIndex: controller.coolingIndex,
                        customDays: controller.customCoolingDays,
                        disabled: disabled,
                        auraBucketIds: [controller.bucketId],
                        onTap: (i) => _onCoolingChanged(context, i),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftCard(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: MemoryStrengthSelector(
                        value: controller.memoryStrength,
                        usesDefault: controller.memoryUsesDefault,
                        disabled: disabled,
                        auraBucketIds: [controller.bucketId],
                        onChanged: controller.setBucketMemoryStrength,
                        onClear: controller.clearBucketMemoryStrength,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AccountReminderRow(
                      readout: dropReadinessShortLabel(
                          controller.accountDropFrequency.value),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showHowItWorksSheet(
                          context,
                          title: HowItWorksCopy.bucketConfigTitle,
                          sections: HowItWorksCopy.bucketConfigSections,
                          auraPrompt:
                              'Explain how bucket config shapes my reviews.',
                          auraBucketIds: [controller.bucketId],
                        ),
                        child: Text(
                          'What is Bucket config?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.grey600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          Obx(() {
            if (!controller.hasPendingChanges.value) {
              return const SizedBox.shrink();
            }
            return _ConfigSaveBar(
              isSaving: controller.isSavingConfig.value,
              onSave: controller.onSaveConfig,
              onDiscard: controller.onDiscardConfig,
            );
          }),
        ],
      ),
    );
  }

  Future<void> _onDone(BuildContext context) async {
    if (controller.hasPendingChanges.value) {
      await controller.onSaveConfig();
    }
    Get.back();
  }

  Future<void> _onCoolingChanged(BuildContext context, int index) async {
    if (index == CoolingPeriodSelector.customIndex) {
      final days = await showCustomCoolingDialog(
        context: context,
        initialDays: controller.customCoolingDays ?? 14,
      );
      if (days != null) controller.onCustomCoolingChanged(days);
      return;
    }
    controller.onCoolingChanged(index);
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onDone;
  const _Header({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Bucket config',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              RecallHaptics.selection();
              onDone();
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 20, color: c.inkOnInk),
            ),
          ),
        ],
      ),
    );
  }
}

/// Account-wide reminder row: clearly not a per-bucket lever. Deep-links to
/// Settings where Reminder style actually lives.
class _AccountReminderRow extends StatelessWidget {
  final String readout;
  const _AccountReminderRow({required this.readout});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RecallHaptics.selection();
        Get.toNamed(Routes.settings);
      },
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CARDS BEFORE A DROP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: c.grey500,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.grey300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Account-wide',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            color: c.grey600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$readout · set once in Settings',
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: c.grey500, height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.grey500),
          ],
        ),
      ),
    );
  }
}

class _RevisionOffNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border.all(color: c.grey200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: c.grey500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Spaced revision is off for this bucket, so these dials are paused. '
              'Turn it on to schedule reviews.',
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: c.grey600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _ConfigSaveBar({
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.grey200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isSaving ? null : onDiscard,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.grey200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Discard',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.grey600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: isSaving ? null : onSave,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSaving ? c.grey400 : c.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.inkOnInk),
                      )
                    : Text(
                        'Save changes',
                        style: GoogleFonts.inter(
                          fontSize: 15,
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
