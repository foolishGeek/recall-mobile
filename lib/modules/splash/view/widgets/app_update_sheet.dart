// Force / soft update bottomsheets. Brand chrome matches AiCooldownSheet.
// Force: no close. Soft: footer CTA + circular X.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../data/services/play_update_service.dart';
import '../../../../data/services/remote_config_service.dart';

class AppUpdateSheet extends StatelessWidget {
  final AppUpdateCopy copy;
  final bool force;

  const AppUpdateSheet({
    super.key,
    required this.copy,
    required this.force,
  });

  static Future<void> showForce(AppUpdateCopy copy) {
    return Get.bottomSheet(
      AppUpdateSheet(copy: copy, force: true),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0x00000000),
    );
  }

  static Future<void> showSoft(AppUpdateCopy copy) {
    return Get.bottomSheet(
      AppUpdateSheet(copy: copy, force: false),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0x00000000),
    );
  }

  Future<void> _onUpdate() async {
    final play = Get.isRegistered<PlayUpdateService>()
        ? Get.find<PlayUpdateService>()
        : PlayUpdateService();
    await play.startUpdate(force: force);
  }

  void _onClose() {
    if (force) return;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return PopScope(
      canPop: !force,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.grey200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MonoLabel(
                      copy.versionLabel,
                      color: c.grey500,
                      size: 9.5,
                      tracking: 0.2,
                    ),
                  ),
                  if (!force)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onClose,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: c.grey500,
                        ),
                      ),
                    ),
                ],
              ),
              if (force) const SizedBox(height: 12) else const SizedBox(height: 4),
              Text(copy.title, style: t.headingMd.copyWith(color: c.ink)),
              const SizedBox(height: 8),
              Text(
                copy.description,
                style: t.body.copyWith(color: c.grey600),
              ),
              const SizedBox(height: 22),
              _PrimaryButton(
                label: copy.cta,
                onTap: _onUpdate,
                color: c.ink,
                textColor: c.inkOnInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecallType.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: t.label.copyWith(color: textColor)),
      ),
    );
  }
}
