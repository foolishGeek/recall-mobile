import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/neo_chip.dart';

class NodeChipRow extends StatelessWidget {
  final int priority;
  final int difficulty;
  final int comfort;
  final bool comfortReadOnly;
  final String priorityLabel;
  final String difficultyLabel;
  final String comfortLabel;
  final NeoLevel priorityLevel;
  final NeoLevel difficultyLevel;
  final NeoLevel comfortLevel;
  final VoidCallback onPriorityTap;
  final VoidCallback onDifficultyTap;
  final VoidCallback onComfortTap;

  const NodeChipRow({
    super.key,
    required this.priority,
    required this.difficulty,
    required this.comfort,
    required this.comfortReadOnly,
    required this.priorityLabel,
    required this.difficultyLabel,
    required this.comfortLabel,
    required this.priorityLevel,
    required this.difficultyLevel,
    required this.comfortLevel,
    required this.onPriorityTap,
    required this.onDifficultyTap,
    required this.onComfortTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final labelStyle = GoogleFonts.jetBrainsMono(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: c.grey500,
      letterSpacing: 0.22,
    );

    // Each column keeps its label directly above its chip and the three pairs
    // are evenly distributed across the width — no trailing dead space.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetaColumn(
            label: 'PRIORITY',
            labelStyle: labelStyle,
            chip: _ChipPopButton(
              chipLabel: priorityLabel,
              level: priorityLevel,
              onTap: onPriorityTap,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaColumn(
            label: 'DIFFICULTY',
            labelStyle: labelStyle,
            chip: _ChipPopButton(
              chipLabel: difficultyLabel,
              level: difficultyLevel,
              onTap: onDifficultyTap,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaColumn(
            label: 'COMFORT',
            labelStyle: labelStyle,
            chip: _ChipPopButton(
              chipLabel: comfortLabel,
              level: comfortLevel,
              onTap: comfortReadOnly ? null : onComfortTap,
              dimmed: comfortReadOnly,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single meta column: mono micro-label on top, its chip 8px below,
/// both left-aligned so the trio reads as an aligned grid.
class _MetaColumn extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final Widget chip;

  const _MetaColumn({
    required this.label,
    required this.labelStyle,
    required this.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: chip),
      ],
    );
  }
}

/// Wraps a NeoChip with the chipPop scale animation:
/// 1 → 1.18 → 0.94 → 1 over RecallMotion.normal.
class _ChipPopButton extends StatefulWidget {
  final String chipLabel;
  final NeoLevel level;
  final VoidCallback? onTap;
  final bool dimmed;

  const _ChipPopButton({
    required this.chipLabel,
    required this.level,
    this.onTap,
    this.dimmed = false,
  });

  @override
  State<_ChipPopButton> createState() => _ChipPopButtonState();
}

class _ChipPopButtonState extends State<_ChipPopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: RecallMotion.normal,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.94), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 35),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap == null) return;
    _ctrl.forward(from: 0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final proto = NeoChip.priority(widget.level, label: widget.chipLabel);
    final chip = NeoChip(
      label: proto.label,
      color: proto.color,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      fontSize: 10.5,
      borderRadius: 7,
    );
    final child = widget.dimmed
        ? Opacity(opacity: 0.45, child: chip)
        : chip;

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(scale: _scale, child: child),
    );
  }
}
