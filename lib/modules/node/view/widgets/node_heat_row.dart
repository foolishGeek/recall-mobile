import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/heat_ring.dart';

class NodeHeatRow extends StatelessWidget {
  final double heatPct;
  final String dueLabel;

  const NodeHeatRow({
    super.key,
    required this.heatPct,
    required this.dueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final heat = (heatPct / 100.0).clamp(0.0, 1.0);
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: c.grey500,
      letterSpacing: 0.18,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HeatRing(
          progress: heat,
          heat: heat,
          size: 38,
          inset: 4,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HEAT · ${heatPct.toStringAsFixed(0)}%', style: mono),
            const SizedBox(height: 3),
            Text(dueLabel, style: mono),
          ],
        ),
      ],
    );
  }
}
