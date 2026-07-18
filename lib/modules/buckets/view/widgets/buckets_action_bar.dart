import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_shape.dart';

/// The pinned pair of CTAs at the bottom of the Buckets tab. Replaces the old
/// single "+" FAB with an explicit "Create a Bucket" (primary) and
/// "Create a note" (secondary). Kept compact so it reads as a quiet toolbar.
class BucketsActionBar extends StatelessWidget {
  final bool bucketLocked;
  final VoidCallback onCreateBucket;
  final VoidCallback onCreateNote;

  const BucketsActionBar({
    super.key,
    required this.bucketLocked,
    required this.onCreateBucket,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Create a Bucket',
            icon: bucketLocked
                ? Icons.lock_outline
                : Icons.create_new_folder_outlined,
            filled: true,
            onTap: onCreateBucket,
            c: c,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Create a note',
            icon: Icons.note_add_outlined,
            filled: false,
            onTap: onCreateNote,
            c: c,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final RecallColors c;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    required this.c,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final filled = widget.filled;

    final bg = filled ? c.ink : c.card;
    final fg = filled ? c.inkOnInk : c.ink;
    final iconColor = filled ? c.inkOnInk : c.grey500;
    final shadow = filled
        ? Colors.black.withValues(alpha: dark ? 0.45 : 0.16)
        : Colors.black.withValues(alpha: 0.04);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: RecallMotion.fast,
      curve: RecallMotion.bubbly,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: filled ? c.ink : c.grey200,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(RecallShape.radiusMd),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, filled ? (dark ? 12 : 10) : 6),
                blurRadius: filled ? (dark ? 24 : 20) : 16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
