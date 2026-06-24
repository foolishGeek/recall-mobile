// Recall · ListRow. The standard settings/profile row used everywhere — title +
// optional subtitle + trailing chevron / icon / toggle. Used in Settings and
// You tab.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_shape.dart';
import '../utils/recall_haptics.dart';

class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool divider;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.titleColor,
    this.onTap,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final cap = trailing ?? Icon(Icons.chevron_right, size: 18, color: c.grey400);

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              RecallHaptics.selection();
              onTap!();
            },
      child: Container(
        decoration: BoxDecoration(
          border: divider
              ? Border(
                  bottom: BorderSide(
                    color: c.grey300.withValues(alpha: 0.7),
                    width: 1,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 17, color: c.ink),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: titleColor ?? c.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: c.grey500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            cap,
          ],
        ),
      ),
    );
  }
}

class RecallToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const RecallToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: () {
        RecallHaptics.selection();
        onChanged?.call(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: value ? c.ink : c.grey300,
          borderRadius: RecallShape.pill,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(2),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? c.inkOnInk : c.card,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
