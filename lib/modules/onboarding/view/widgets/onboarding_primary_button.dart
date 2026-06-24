// Recall · onboarding CTA. Pixel match to Recall Onboarding.dc.html — no border,
// no trailing icon, 0.94 press scale on inner fill only, 360ms bubbly spring.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';

class OnboardingPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fixed shadow footprint — does not scale on press.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.4 : 0.18),
                    offset: const Offset(0, 12),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          AnimatedScale(
            scale: _pressed && !disabled ? 0.94 : 1.0,
            duration: RecallMotion.ctaPress,
            curve: RecallMotion.bubbly,
            child: GestureDetector(
              onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: disabled
                  ? null
                  : (_) {
                      setState(() => _pressed = false);
                      RecallHaptics.light();
                      widget.onPressed?.call();
                    },
              child: AnimatedOpacity(
                duration: RecallMotion.fast,
                opacity: disabled ? 0.55 : 1,
                child: Container(
                  height: 56,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.005 * 16.5,
                      color: c.inkOnInk,
                      height: 1.0,
                    ),
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
