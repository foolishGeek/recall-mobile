import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/aura_mark.dart';

class BucketAiChips extends StatelessWidget {
  final bool isSummarizing;
  final bool disabled;
  final VoidCallback onSummarize;
  final VoidCallback onAskAi;

  const BucketAiChips({
    super.key,
    required this.isSummarizing,
    this.disabled = false,
    required this.onSummarize,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AuraSectionHeader(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AiButton(
                    label: 'Summarize',
                    icon: Icons.summarize_outlined,
                    isLoading: isSummarizing,
                    onTap: onSummarize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AiButton(
                    label: 'Ask Aura',
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: onAskAi,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuraSectionHeader extends StatelessWidget {
  const _AuraSectionHeader();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        const AuraMark(size: 14),
        const SizedBox(width: 7),
        Text(
          AuraBrand.full.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: c.grey500,
            letterSpacing: 0.16 * 9.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: c.grey200),
        ),
      ],
    );
  }
}

class _AiButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _AiButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final loading = widget.isLoading;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: RecallMotion.fast,
      curve: RecallMotion.bubbly,
      child: GestureDetector(
        onTapDown: loading ? null : (_) => setState(() => _pressed = true),
        onTapCancel: loading ? null : () => setState(() => _pressed = false),
        onTapUp: loading
            ? null
            : (_) {
                setState(() => _pressed = false);
                RecallHaptics.light();
                widget.onTap();
              },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
              if (loading)
                const AuraMark(size: 17)
              else
                Icon(widget.icon, size: 17, color: c.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  loading ? 'Summarizing' : widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
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
