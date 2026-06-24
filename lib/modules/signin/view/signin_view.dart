// Recall · SigninView. S08: full-bleed centered welcome — lockup in the upper
// region, provider buttons + email magic link below. Two states: notSent and
// sent. Monochrome, strictly from design tokens.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_motion.dart';
import '../controller/signin_controller.dart';
import 'widgets/signin_email_section.dart';
import 'widgets/signin_legal_footer.dart';
import 'widgets/signin_lockup.dart';
import 'widgets/signin_provider_buttons.dart';
import 'widgets/signin_sent_card.dart';

class SigninView extends GetView<SigninController> {
  const SigninView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const SigninLockup(),
              const Spacer(flex: 2),
              _AuthStack(controller: controller),
              const SizedBox(height: 24),
              SigninLegalFooter(controller: controller),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthStack extends StatelessWidget {
  final SigninController controller;
  const _AuthStack({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSent = controller.state.value == SigninState.sent;

      return AnimatedSize(
        duration: RecallMotion.normal,
        curve: RecallMotion.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SigninProviderButtons(controller: controller),
            const SizedBox(height: 20),
            if (isSent)
              SigninSentCard(controller: controller)
            else
              SigninEmailSection(controller: controller),
          ],
        ),
      );
    });
  }
}
