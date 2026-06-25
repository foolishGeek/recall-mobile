import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/enums.dart';

class ReviewDirectionStamp extends StatelessWidget {
  final ReviewGrade grade;
  final double opacity;

  const ReviewDirectionStamp({
    super.key,
    required this.grade,
    required this.opacity,
  });

  String get _label {
    switch (grade) {
      case ReviewGrade.good:
        return 'GOOD \u2713';
      case ReviewGrade.hard:
        return 'HARD';
      case ReviewGrade.easy:
        return 'EASY \u2191';
      case ReviewGrade.again:
        return 'FORGOT \u21BA';
    }
  }

  double get _rotation {
    switch (grade) {
      case ReviewGrade.good:
        return -8 * (math.pi / 180);
      case ReviewGrade.hard:
        return 12 * (math.pi / 180);
      case ReviewGrade.easy:
        return -5 * (math.pi / 180);
      case ReviewGrade.again:
        return 5 * (math.pi / 180);
    }
  }

  Alignment get _alignment {
    switch (grade) {
      case ReviewGrade.good:
        return Alignment.topLeft;
      case ReviewGrade.hard:
        return Alignment.topRight;
      case ReviewGrade.easy:
        return Alignment.topCenter;
      case ReviewGrade.again:
        return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Positioned(
      top: _alignment == Alignment.bottomCenter ? null : 24,
      bottom: _alignment == Alignment.bottomCenter ? 24 : null,
      left: _alignment == Alignment.topLeft ? 24 : null,
      right: _alignment == Alignment.topRight ? 24 : null,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: _rotation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: c.ink, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 12 * 0.18,
                color: c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
