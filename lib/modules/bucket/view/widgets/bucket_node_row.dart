import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../data/models/node.dart';

class BucketNodeRow extends StatelessWidget {
  final Node node;
  final String dueLabel;
  final VoidCallback onTap;

  const BucketNodeRow({
    super.key,
    required this.node,
    required this.dueLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // A note opted out of spaced revision has no due schedule —
                    // show a calm status line instead of a stale due label.
                    node.srEnabled ? dueLabel : 'Saved · not in revision',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: c.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ..._buildChips(c),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChips(RecallColors c) {
    final chips = <Widget>[];
    final pLevel = _priorityLevel(node.priority);
    final dLevel = _difficultyLevel(node.difficulty);

    if (pLevel != null) {
      chips.add(_microChip(c, pLevel, _priorityLabel(node.priority)));
    }
    if (dLevel != null) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 4));
      chips.add(_microChip(c, dLevel, _difficultyLabel(node.difficulty)));
    }
    return chips;
  }

  // Tiny neo chip — bucket-row size (h18, pad h6, mono 8.5, radius 5, 1.5 shadow).
  Widget _microChip(RecallColors c, NeoLevel level, String label) {
    return NeoChip(
      label: label,
      color: _levelColor(c, level),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      fontSize: 8.5,
      borderRadius: 5,
      shadowOffset: 1.5,
    );
  }

  Color _levelColor(RecallColors c, NeoLevel level) {
    switch (level) {
      case NeoLevel.high:
        return c.chipRed;
      case NeoLevel.medium:
        return c.chipAmber;
      case NeoLevel.low:
        return c.chipGreen;
    }
  }

  NeoLevel? _priorityLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return null;
  }

  NeoLevel? _difficultyLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return null;
  }

  String _priorityLabel(int val) {
    if (val >= 4) return 'HIGH';
    return 'MED';
  }

  String _difficultyLabel(int val) {
    if (val >= 4) return 'HARD';
    return 'MED';
  }
}
