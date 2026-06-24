import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/list_row.dart';
import '../../controller/onboarding_controller.dart';

class OnboardingPanelC extends GetView<OnboardingController> {
  const OnboardingPanelC({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/illustrations/onboarding-buckets.svg',
            height: 160,
            colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
          ),
          const SizedBox(height: 28),
          Text(
            'Make your first bucket.',
            textAlign: TextAlign.center,
            style: t.displaySm.copyWith(color: c.ink),
          ),
          const SizedBox(height: 12),
          Text(
            "Buckets hold what you're learning. Name one to begin, and turn on "
            'Recall Drop for a gentle daily nudge.',
            textAlign: TextAlign.center,
            style: t.body.copyWith(color: c.grey600, height: 1.55),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.grey200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recall Drop',
                          style: t.label.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily nudge — calm, optional',
                          style: t.monoLabelSm.copyWith(color: c.grey500),
                        ),
                      ],
                    ),
                  ),
                  RecallToggle(
                    value: controller.dropEnabled.value,
                    onChanged: controller.setDropEnabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
