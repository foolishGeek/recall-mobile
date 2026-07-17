import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// Due-only row for node detail (heat retired).
class NodeHeatRow extends StatelessWidget {
  final double heatPct;
  final String dueLabel;

  const NodeHeatRow({
    super.key,
    this.heatPct = 0,
    required this.dueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: c.grey500,
      letterSpacing: 0.18,
    );
    return Text(dueLabel, style: mono);
  }
}
