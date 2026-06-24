// Recall · MonoLabel. All-caps, JetBrains Mono, tracked. Used everywhere as the
// quiet section header above a card.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';

class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  final double tracking; // em
  final FontWeight weight;
  final EdgeInsets padding;

  const MonoLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 10,
    this.tracking = 0.18,
    this.weight = FontWeight.w500,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: size,
          fontWeight: weight,
          color: color ?? c.grey500,
          letterSpacing: size * tracking,
          height: 1.3,
        ),
      ),
    );
  }
}
