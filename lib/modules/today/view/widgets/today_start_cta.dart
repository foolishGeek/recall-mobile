import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';

class TodayStartCta extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const TodayStartCta({
    super.key,
    required this.label,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  State<TodayStartCta> createState() => _TodayStartCtaState();
}

class _TodayStartCtaState extends State<TodayStartCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: RecallMotion.ctaPress,
      curve: RecallMotion.bubbly,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!widget.isLoading) {
            RecallHaptics.light();
            widget.onPressed?.call();
          }
        },
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: c.ink,
            border: Border.all(color: c.ink, width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
                offset: Offset(0, dark ? 8 : 6),
                blurRadius: dark ? 20 : 16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.inkOnInk,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 15.5 * -0.01,
                        color: c.inkOnInk,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: c.inkOnInk,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
