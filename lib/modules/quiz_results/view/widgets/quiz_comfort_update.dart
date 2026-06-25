import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/models.dart';
import 'quiz_section_header.dart';

/// "COMFORT UPDATE" — the second (and only other) appearance of neo chips:
/// before-chip (faded) → arrow → after-chip (full). The arrow tilts down when
/// comfort dropped; the after-chip springs in with a staggered bubbly overshoot.
/// Source: `comfort_updates[]` [D-EF-3].
class QuizComfortUpdateSection extends StatelessWidget {
  final List<QuizComfortUpdate> updates;

  const QuizComfortUpdateSection({super.key, required this.updates});

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) return const SizedBox.shrink();

    final up = updates.where((u) => u.bumpedUp).length;
    final down = updates.length - up;
    final note = down == 0
        ? '$up nudged up'
        : up == 0
            ? '$down nudged down'
            : '$up up · $down down';

    final rows = <Widget>[];
    for (var i = 0; i < updates.length; i++) {
      if (i > 0) rows.add(const QuizRowDivider());
      rows.add(_ComfortRow(update: updates[i], index: i));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizSectionHeader(title: 'Comfort update', note: note),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          radius: 22,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

class _ComfortRow extends StatefulWidget {
  final QuizComfortUpdate update;
  final int index;
  const _ComfortRow({required this.update, required this.index});

  @override
  State<_ComfortRow> createState() => _ComfortRowState();
}

class _ComfortRowState extends State<_ComfortRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: 80 * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final u = widget.update;
    final before = _ComfortChip.of(u.comfortBefore, c, faded: true, height: 22, fontSize: 9);
    final after = _ComfortChip.of(u.comfortAfter, c, height: 28, fontSize: 10);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  u.bumpedUp ? 'BUMPED UP' : 'NUDGED DOWN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: c.grey500,
                  ),
                ),
              ],
            ),
          ),
          before,
          const SizedBox(width: 10),
          Transform.rotate(
            angle: u.bumpedUp ? 0 : 3.14159,
            child: Icon(Icons.arrow_forward, size: 14, color: c.grey500),
          ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: RecallMotion.bubbly),
            ),
            child: after,
          ),
        ],
      ),
    );
  }
}

/// A comfort neo chip. Comfort ≥70 → HIGH (green), ≥40 → MED (amber), else LOW
/// (red). The before-chip renders faded; the after-chip is at full strength.
class _ComfortChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool faded;
  final double height;
  final double fontSize;

  const _ComfortChip({
    required this.label,
    required this.color,
    required this.height,
    required this.fontSize,
    this.faded = false,
  });

  factory _ComfortChip.of(
    int? comfort,
    RecallColors c, {
    required double height,
    required double fontSize,
    bool faded = false,
  }) {
    final v = comfort ?? 0;
    final String label;
    final Color color;
    if (v >= 70) {
      label = 'HIGH';
      color = c.chipGreen;
    } else if (v >= 40) {
      label = 'MED';
      color = c.chipAmber;
    } else {
      label = 'LOW';
      color = c.chipRed;
    }
    return _ComfortChip(
      label: label,
      color: color,
      height: height,
      fontSize: fontSize,
      faded: faded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = NeoChip(label: label, color: color, height: height, fontSize: fontSize);
    return faded ? Opacity(opacity: 0.45, child: chip) : chip;
  }
}
