// Recall · buttons. Two flavors.
//
//   PrimaryButton(label: 'Go Premium', onPressed: ...)     // solid ink anchor
//   SecondaryButton(label: 'Review ahead anyway', onPressed: ...)
//
// Both honor the bubbly press animation (positive-moment scale) and trigger a
// light haptic on press. They never use color.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../theme/recall_shape.dart';
import '../utils/recall_haptics.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;
  final double height;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing = Icons.arrow_forward,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shadow = Colors.black.withValues(alpha: dark ? 0.45 : 0.16);

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
          widget.onPressed?.call();
        },
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: c.ink,
            border: Border.all(color: c.ink, width: 1.5),
            borderRadius: BorderRadius.circular(RecallShape.radiusMd + 2),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, dark ? 14 : 12),
                blurRadius: dark ? 28 : 24,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.inkOnInk,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                Icon(widget.trailing, color: c.inkOnInk, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: () {
        RecallHaptics.selection();
        onPressed?.call();
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1.5),
          borderRadius: BorderRadius.circular(RecallShape.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Icon(trailing, color: c.grey500, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// Tertiary — text only, almost invisible (e.g. "Restore purchases").
class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const TextLinkButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c.grey600,
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
