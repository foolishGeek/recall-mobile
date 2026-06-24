import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../controller/onboarding_controller.dart';
import 'widgets/onboarding_dots.dart';
import 'widgets/onboarding_panel_a.dart';
import 'widgets/onboarding_panel_b.dart';
import 'widgets/onboarding_panel_c.dart';
import 'widgets/onboarding_primary_button.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return RecallScaffold.bare(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            clipBehavior: Clip.hardEdge,
            physics: const ClampingScrollPhysics(),
            children: const [
              OnboardingPanelA(),
              OnboardingPanelB(),
              OnboardingPanelC(),
            ],
          ),
          Obx(() {
            if (!controller.showSkip) return const SizedBox.shrink();
            return Positioned(
              top: 20,
              right: 22,
              child: GestureDetector(
                onTap: controller.skip,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: c.grey500,
                    ),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    c.canvas,
                    c.canvas.withValues(alpha: 0),
                  ],
                  stops: const [0.64, 1.0],
                ),
              ),
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingDots(
                      count: 3,
                      active: controller.currentPage.value,
                      onDotTap: controller.goToPage,
                    ),
                    const SizedBox(height: 22),
                    OnboardingPrimaryButton(
                      label: controller.primaryLabel,
                      onPressed: controller.isCompleting.value
                          ? null
                          : controller.onPrimaryPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
