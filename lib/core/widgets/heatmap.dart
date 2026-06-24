// Recall · calendar Heatmap. 12 columns (weeks) × 7 rows (days). Each cell uses
// a 5-stop monochrome scale. Deterministic data builder included for previews.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';

// 5-stop monochrome heat scale (cool → hot), per theme.
const _heatScaleDark = [
  Color(0xFF1A1A20),
  Color(0xFF2E2E36),
  Color(0xFF4B4B55),
  Color(0xFF8A8A93),
  Color(0xFFF5F4F1),
];
const _heatScaleLight = [
  Color(0xFFEFEDE8),
  Color(0xFFD6D3CC),
  Color(0xFF9B9890),
  Color(0xFF4D4B47),
  Color(0xFF111111),
];

List<Color> _scaleFor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? _heatScaleDark
        : _heatScaleLight;

class Heatmap extends StatelessWidget {
  /// 12 columns × 7 cells each. Values 0..4 mapping to the 5-stop scale.
  final List<List<int>> data;
  final double cellHeight;
  final double cellGap;
  final double radius;

  const Heatmap({
    super.key,
    required this.data,
    this.cellHeight = 11,
    this.cellGap = 3,
    this.radius = 2.5,
  });

  /// Stable pseudo-random sample for previews / empty states.
  static List<List<int>> sample({int seed = 7}) {
    int s = seed;
    double rand() {
      s = (s * 9301 + 49297) % 233280;
      return s / 233280;
    }

    return List.generate(12, (c) {
      return List.generate(7, (r) {
        final v = rand();
        final w = v * 0.55 + (c / 12) * 0.45;
        if (w < 0.28) return 0;
        if (w < 0.48) return 1;
        if (w < 0.68) return 2;
        if (w < 0.86) return 3;
        return 4;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scaleFor(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        for (int col = 0; col < data.length; col++) ...[
          Expanded(
            child: Column(
              children: [
                for (int row = 0; row < data[col].length; row++) ...[
                  Container(
                    height: cellHeight,
                    decoration: BoxDecoration(
                      color: scale[data[col][row]],
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                  if (row != data[col].length - 1) SizedBox(height: cellGap),
                ],
              ],
            ),
          ),
          if (col != data.length - 1) SizedBox(width: cellGap),
        ],
      ],
    );
  }
}

/// Small "less … more" legend strip that lives under the heatmap.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final scale = _scaleFor(context);
    final labelStyle = GoogleFonts.jetBrainsMono(
      fontSize: 9.5,
      color: c.grey500,
      letterSpacing: 1.2,
    );
    return Row(
      children: [
        Text('LESS', style: labelStyle),
        const SizedBox(width: 6),
        for (final color in scale) ...[
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 2),
        Text('MORE', style: labelStyle),
      ],
    );
  }
}
