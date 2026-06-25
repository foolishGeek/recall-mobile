import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

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
            label: 'Summarize',
            modelLabel: modelLabel,
            isLoading: isSummarizing,
            onTap: onSummarize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AiChipButton(
            label: 'Ask AI',
            modelLabel: modelLabel,
            onTap: onAskAi,
          ),
        ),
      ],
    );
  }
}

class _AiChipButton extends StatefulWidget {
  final String label;
  final String modelLabel;
  final bool isLoading;
  final VoidCallback onTap;

  const _AiChipButton({
    required this.label,
    required this.modelLabel,
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
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.grey200),
          ),
          child: Row(
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.ink,
                  ),
                )
              else
                Icon(Icons.auto_awesome_outlined, size: 15, color: c.ink),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: c.grey300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.modelLabel.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    color: c.grey500,
                    letterSpacing: 0.8,
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
