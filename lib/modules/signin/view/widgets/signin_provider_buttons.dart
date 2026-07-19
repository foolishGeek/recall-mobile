// Recall · provider buttons. "Continue with Apple" (primary) and "Continue with
// Google" (secondary) with leading brand icons. bubbly scale + lightImpact.
// Apple is only shown on iOS; on Android its native flow is unsupported, so
// Google takes the primary slot there.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../controller/signin_controller.dart';

class SigninProviderButtons extends StatelessWidget {
  final SigninController controller;
  const SigninProviderButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final showApple = Platform.isIOS;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showApple) ...[
          _ProviderButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            isPrimary: true,
            onPressed: controller.onContinueWithApple,
          ),
          const SizedBox(height: 12),
        ],
        _ProviderButton(
          label: 'Continue with Google',
          icon: null,
          isPrimary: !showApple,
          onPressed: controller.onContinueWithGoogle,
          customIcon: _GoogleIcon(),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
    this.customIcon,
  });

  @override
  State<_ProviderButton> createState() => _ProviderButtonState();
}

class _ProviderButtonState extends State<_ProviderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final bg = widget.isPrimary ? c.ink : c.card;
    final fg = widget.isPrimary ? c.inkOnInk : c.ink;
    final border = widget.isPrimary ? c.ink : c.grey200;
    final shadow = Colors.black.withValues(
      alpha: widget.isPrimary ? (dark ? 0.45 : 0.14) : 0.04,
    );
    final shadowOffset = widget.isPrimary ? 10.0 : 6.0;
    final shadowBlur = widget.isPrimary ? 24.0 : 16.0;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: RecallMotion.fast,
      curve: RecallMotion.bubbly,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          RecallHaptics.light();
          widget.onPressed();
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(RecallShape.radiusMd + 2),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, shadowOffset),
                blurRadius: shadowBlur,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.customIcon != null)
                widget.customIcon!
              else if (widget.icon != null)
                Icon(widget.icon, color: fg, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Minimal Google "G" logo painted natively (4-color arc).
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final r = s / 2;
    const sw = 3.6;

    void arc(Color color, double startDeg, double sweepDeg) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - sw / 2),
        startDeg * 3.14159 / 180,
        sweepDeg * 3.14159 / 180,
        false,
        paint,
      );
    }

    arc(const Color(0xFFEA4335), -45, -90); // red (top)
    arc(const Color(0xFFFBBC05), -135, -90); // yellow (left)
    arc(const Color(0xFF34A853), -225, -90); // green (bottom)
    arc(const Color(0xFF4285F4), -315, -45); // blue (right-top)

    // Blue crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(s * 0.48, s * 0.42, s * 0.42, sw),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
