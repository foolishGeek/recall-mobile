// Recall · sent card. Replaces the email section after magic-link send.
// "Check your inbox" + truncated email + "use a different email" link +
// resend with 60s cooldown. Fades in 240ms after the AnimatedSize collapse.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../controller/signin_controller.dart';

class SigninSentCard extends StatefulWidget {
  final SigninController controller;
  const SigninSentCard({super.key, required this.controller});

  @override
  State<SigninSentCard> createState() => _SigninSentCardState();
}

class _SigninSentCardState extends State<SigninSentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OrDivider(c: c, t: t),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.grey200, width: 1),
              borderRadius: BorderRadius.circular(RecallShape.radiusMd + 2),
            ),
            child: Column(
              children: [
                Text(
                  'Check your inbox',
                  style: t.serifItalic.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                      'we sent a link to ${widget.controller.sentEmail.value ?? ''}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: c.grey500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ResendButton(controller: widget.controller, c: c),
              const SizedBox(width: 6),
              Text('·', style: TextStyle(color: c.grey400, fontSize: 14)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.controller.onUseDifferentEmail,
                child: Text(
                  'use a different email',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.grey600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _ResendButton extends StatelessWidget {
  final SigninController controller;
  final RecallColors c;
  const _ResendButton({required this.controller, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cd = controller.resendCooldown.value;
      final canResend = cd <= 0;

      return GestureDetector(
        onTap: canResend ? controller.onResendMagicLink : null,
        child: Text(
          canResend ? 'Resend' : 'Resend (${cd}s)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: canResend ? c.ink : c.grey400,
          ),
        ),
      );
    });
  }
}
