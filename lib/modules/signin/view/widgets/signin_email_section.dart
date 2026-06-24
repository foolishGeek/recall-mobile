// Recall · email section. OR divider, email TextField (radius 18, height 56),
// "Send magic link →" text link. Inline error below field on failure.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../controller/signin_controller.dart';

class SigninEmailSection extends StatelessWidget {
  final SigninController controller;
  const SigninEmailSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OrDivider(c: c, t: t),
        const SizedBox(height: 20),
        _EmailField(controller: controller, c: c),
        Obx(() {
          final error = controller.errorText.value;
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: c.grey600,
                height: 1.4,
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _SendMagicLinkButton(controller: controller, c: c),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final RecallColors c;
  final RecallType t;
  const _OrDivider({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: c.grey200, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: t.monoLabel.copyWith(color: c.grey500),
          ),
        ),
        Expanded(child: Divider(color: c.grey200, height: 1)),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final SigninController controller;
  final RecallColors c;
  const _EmailField({required this.controller, required this.c});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller.emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => controller.onSendMagicLink(),
        style: GoogleFonts.inter(fontSize: 15, color: c.ink),
        cursorColor: c.ink,
        decoration: InputDecoration(
          hintText: 'Email address',
          hintStyle: GoogleFonts.inter(fontSize: 15, color: c.grey500),
          filled: true,
          fillColor: c.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RecallShape.radiusMd + 2),
            borderSide: BorderSide(color: c.grey200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RecallShape.radiusMd + 2),
            borderSide: BorderSide(color: c.ink, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SendMagicLinkButton extends StatelessWidget {
  final SigninController controller;
  final RecallColors c;
  const _SendMagicLinkButton({required this.controller, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.state.value == SigninState.loading;
      return GestureDetector(
        onTap: loading
            ? null
            : () {
                RecallHaptics.selection();
                controller.onSendMagicLink();
              },
        child: Opacity(
          opacity: loading ? 0.5 : 1.0,
          child: Text(
            'Send magic link →',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.grey600,
            ),
          ),
        ),
      );
    });
  }
}
