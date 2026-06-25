// Recall · NeoChip. The ONLY thing in the app that carries color.
// Small pill / rounded rect. Flat solid fill, 1.5px ink outline, hard 2/2 offset shadow.
// UPPERCASE mono micro-label.
//
//   NeoChip.priority(NeoLevel.high)    // HARD / HIGH PRI / LOW COMF
//   NeoChip.priority(NeoLevel.medium)  // MED
//   NeoChip.priority(NeoLevel.low)     // EASY / LOW PRI / HIGH COMF
//   NeoChip(label: 'HARD', color: c.chipRed)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';

enum NeoLevel { high, medium, low }

class NeoChip extends StatelessWidget {
  final String label;
  final Color color;
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double borderRadius;
  final double shadowOffset;

  const NeoChip({
    super.key,
    required this.label,
    required this.color,
    this.height = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.fontSize = 9.5,
    this.borderRadius = 6,
    this.shadowOffset = 2,
  });

  factory NeoChip.priority(NeoLevel level, {String? label}) {
    const colors = RecallColors.light;
    switch (level) {
      case NeoLevel.high:
        return NeoChip(label: label ?? 'HARD', color: colors.chipRed);
      case NeoLevel.medium:
        return NeoChip(label: label ?? 'MED', color: colors.chipAmber);
      case NeoLevel.low:
        return NeoChip(label: label ?? 'EASY', color: colors.chipGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chip ink/outline is always #111 in both themes (design-tokens §1).
    const ink = Color(0xFF111111);
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: ink, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: ink,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: 0.8,
          height: 1,
        ),
      ),
    );
  }
}
