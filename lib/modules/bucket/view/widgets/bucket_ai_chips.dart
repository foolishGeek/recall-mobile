import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';

class BucketAiChips extends StatelessWidget {
  final String modelLabel;
  final bool isSummarizing;
  final VoidCallback onSummarize;
  final VoidCallback onAskAi;

  const BucketAiChips({
    super.key,
    required this.modelLabel,
    required this.isSummarizing,
    required this.onSummarize,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AiChipButton(
            label: 'Summarize bucket',
            modelTag: 'Aura',
            icon: Icons.sort,
            isLoading: isSummarizing,
            onTap: onSummarize,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AiChipButton(
            label: 'Ask Aura',
            modelTag: 'Aura',
            icon: Icons.refresh,
            onTap: onAskAi,
          ),
        ),
      ],
    );
  }
}

class _AiChipButton extends StatefulWidget {
  final String label;
  final String modelTag;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _AiChipButton({
    required this.label,
    required this.modelTag,
    required this.icon,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<_AiChipButton> createState() => _AiChipButtonState();
}

class _AiChipButtonState extends State<_AiChipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: RecallMotion.bubbly),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        RecallHaptics.light();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.ink, width: 1.2),
          ),
          child: Row(
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.ink,
                  ),
                )
              else
                Icon(widget.icon, size: 16, color: c.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.modelTag.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: c.grey500,
                        letterSpacing: 0.12 * 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
