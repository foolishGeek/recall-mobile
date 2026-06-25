import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// The single primary CTA below the card — "Submit answer" or "Reveal".
class QuizSubmitBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final IconData? icon;
  final VoidCallback onTap;

  const QuizSubmitBar({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.icon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = enabled && !loading;
    final bg = active ? c.ink : c.grey300;
    final fg = active ? c.inkOnInk : c.grey500;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: c.ink.withValues(alpha: dark ? 0.5 : 0.2),
                    offset: const Offset(0, 12),
                    blurRadius: 28,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, size: 16, color: fg),
                  ],
                ],
              ),
      ),
    );
  }
}
