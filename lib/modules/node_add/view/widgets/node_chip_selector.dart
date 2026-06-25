import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/neo_chip.dart';

class NodeChipSelector extends StatelessWidget {
  final int priority;
  final int difficulty;
  final int comfort;
  final String priorityLabel;
  final String difficultyLabel;
  final String comfortLabel;
  final NeoLevel priorityLevel;
  final NeoLevel difficultyLevel;
  final NeoLevel comfortLevel;
  final bool comfortReadOnly;
  final VoidCallback onPriorityTap;
  final VoidCallback onDifficultyTap;
  final VoidCallback onComfortTap;

  const NodeChipSelector({
    super.key,
    required this.priority,
    required this.difficulty,
    required this.comfort,
    required this.priorityLabel,
    required this.difficultyLabel,
    required this.comfortLabel,
    required this.priorityLevel,
    required this.difficultyLevel,
    required this.comfortLevel,
    this.comfortReadOnly = false,
    required this.onPriorityTap,
    required this.onDifficultyTap,
    required this.onComfortTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ChipRow(
            title: 'Priority',
            subtitle: 'How urgent it is for you.',
            chipLabel: priorityLabel,
            level: priorityLevel,
            dotValue: priority,
            maxDots: 3,
            onTap: onPriorityTap,
            colors: c,
          ),
          Divider(height: 28, thickness: 1, color: c.grey200),
          _ChipRow(
            title: 'Difficulty',
            subtitle: 'How hard the material is.',
            chipLabel: difficultyLabel,
            level: difficultyLevel,
            dotValue: difficulty,
            maxDots: 3,
            onTap: onDifficultyTap,
            colors: c,
          ),
          Divider(height: 28, thickness: 1, color: c.grey200),
          Opacity(
            opacity: comfortReadOnly ? 0.5 : 1.0,
            child: _ChipRow(
              title: 'Comfort',
              subtitle: 'How well you know it.',
              chipLabel: comfortLabel,
              level: comfortLevel,
              dotValue: _comfortDotIndex(comfort),
              maxDots: 3,
              onTap: comfortReadOnly ? null : onComfortTap,
              colors: c,
            ),
          ),
        ],
      ),
    );
  }

  int _comfortDotIndex(int val) {
    if (val <= 33) return 1;
    if (val <= 66) return 2;
    return 3;
  }
}

class _ChipRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final String chipLabel;
  final NeoLevel level;
  final int dotValue;
  final int maxDots;
  final VoidCallback? onTap;
  final RecallColors colors;

  const _ChipRow({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.level,
    required this.dotValue,
    required this.maxDots,
    this.onTap,
    required this.colors,
  });

  @override
  State<_ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<_ChipRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  int _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.dotValue;
    _animCtrl = AnimationController(
      vsync: this,
      duration: RecallMotion.slow, // 420ms
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.94), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 40),
    ]).animate(_animCtrl);
  }

  @override
  void didUpdateWidget(covariant _ChipRow old) {
    super.didUpdateWidget(old);
    if (widget.dotValue != _prevValue) {
      _prevValue = widget.dotValue;
      _animCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: widget.colors.grey500,
                  ),
                ),
              ],
            ),
          ),
          _DotIndicators(
            value: widget.dotValue,
            max: widget.maxDots,
            colors: widget.colors,
          ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: _scaleAnim,
            child: NeoChip.priority(widget.level, label: widget.chipLabel),
          ),
        ],
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  final int value;
  final int max;
  final RecallColors colors;

  const _DotIndicators({
    required this.value,
    required this.max,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < value;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colors.ink : colors.grey200,
          ),
        );
      }),
    );
  }
}
