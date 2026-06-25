import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/heat_dot.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../data/models/node.dart';

class BucketNodeRow extends StatelessWidget {
  final Node node;
  final String relativeTime;
  final VoidCallback onTap;

  const BucketNodeRow({
    super.key,
    required this.node,
    required this.relativeTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final heat = _nodeHeat(node);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: c.grey300.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: Row(
          children: [
            HeatDot(heat: heat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativeTime,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: c.grey500,
                    ),
                  ),
                ],
              ),
            ),
            if (_chipLevel(node) != null) ...[
              const SizedBox(width: 8),
              NeoChip.priority(_chipLevel(node)!),
            ],
          ],
        ),
      ),
    );
  }

  double _nodeHeat(Node n) {
    if (n.stability == null || n.stability == 0) return 0.3;
    return (n.comfort / 100.0).clamp(0.0, 1.0);
  }

  NeoLevel? _chipLevel(Node n) {
    if (n.priority >= 4) return NeoLevel.high;
    if (n.difficulty >= 4) return NeoLevel.high;
    if (n.priority == 3 && n.difficulty >= 3) return NeoLevel.medium;
    return null;
  }
}
