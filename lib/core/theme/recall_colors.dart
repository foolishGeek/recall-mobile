// Recall · colors. Every hex matches design-tokens.md exactly.
//
// Usage:
//   final c = RecallColors.of(context);   // resolves light or dark
//   Container(color: c.canvas, child: Text('Hello', style: TextStyle(color: c.ink)))
//
// Chip colors are intentionally the same in both modes (these three are the only
// colored pixels in the entire app).

import 'package:flutter/material.dart';

@immutable
class RecallColors extends ThemeExtension<RecallColors> {
  // Surfaces
  final Color canvas;
  final Color card;
  final Color cardSunken;

  // Ink
  final Color ink;
  final Color inkOnInk;

  // Greys
  final Color grey200; // hairline borders
  final Color grey300; // tracks, faint dividers
  final Color grey400; // chevrons, disabled
  final Color grey500; // mono labels, secondary
  final Color grey600; // body secondary

  // Semantic — chips ONLY. Never used for backgrounds, never for icons.
  final Color chipRed;
  final Color chipAmber;
  final Color chipGreen;

  const RecallColors({
    required this.canvas,
    required this.card,
    required this.cardSunken,
    required this.ink,
    required this.inkOnInk,
    required this.grey200,
    required this.grey300,
    required this.grey400,
    required this.grey500,
    required this.grey600,
    this.chipRed = const Color(0xFFE5484D),
    this.chipAmber = const Color(0xFFF5A623),
    this.chipGreen = const Color(0xFF46A758),
  });

  static const light = RecallColors(
    canvas: Color(0xFFF7F6F3),
    card: Color(0xFFFFFFFF),
    cardSunken: Color(0xFFFBFAF7),
    ink: Color(0xFF111111),
    inkOnInk: Color(0xFFF7F6F3),
    grey200: Color(0xFFE7E5E1),
    grey300: Color(0xFFEFEDE8),
    grey400: Color(0xFFC9C6C0),
    grey500: Color(0xFF8A8780),
    grey600: Color(0xFF5C5A55),
  );

  static const dark = RecallColors(
    canvas: Color(0xFF0E0E11),
    card: Color(0xFF16161B),
    cardSunken: Color(0xFF1B1B22),
    ink: Color(0xFFF5F4F1),
    inkOnInk: Color(0xFF0E0E11),
    grey200: Color(0xFF22222A),
    grey300: Color(0xFF2A2A30),
    grey400: Color(0xFF3A3A42),
    grey500: Color(0xFF6E6E78),
    grey600: Color(0xFF9D9C95),
  );

  static RecallColors of(BuildContext context) =>
      Theme.of(context).extension<RecallColors>() ?? RecallColors.light;

  @override
  RecallColors copyWith({
    Color? canvas,
    Color? card,
    Color? cardSunken,
    Color? ink,
    Color? inkOnInk,
    Color? grey200,
    Color? grey300,
    Color? grey400,
    Color? grey500,
    Color? grey600,
    Color? chipRed,
    Color? chipAmber,
    Color? chipGreen,
  }) {
    return RecallColors(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardSunken: cardSunken ?? this.cardSunken,
      ink: ink ?? this.ink,
      inkOnInk: inkOnInk ?? this.inkOnInk,
      grey200: grey200 ?? this.grey200,
      grey300: grey300 ?? this.grey300,
      grey400: grey400 ?? this.grey400,
      grey500: grey500 ?? this.grey500,
      grey600: grey600 ?? this.grey600,
      chipRed: chipRed ?? this.chipRed,
      chipAmber: chipAmber ?? this.chipAmber,
      chipGreen: chipGreen ?? this.chipGreen,
    );
  }

  @override
  RecallColors lerp(ThemeExtension<RecallColors>? other, double t) {
    if (other is! RecallColors) return this;
    return RecallColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardSunken: Color.lerp(cardSunken, other.cardSunken, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkOnInk: Color.lerp(inkOnInk, other.inkOnInk, t)!,
      grey200: Color.lerp(grey200, other.grey200, t)!,
      grey300: Color.lerp(grey300, other.grey300, t)!,
      grey400: Color.lerp(grey400, other.grey400, t)!,
      grey500: Color.lerp(grey500, other.grey500, t)!,
      grey600: Color.lerp(grey600, other.grey600, t)!,
      chipRed: Color.lerp(chipRed, other.chipRed, t)!,
      chipAmber: Color.lerp(chipAmber, other.chipAmber, t)!,
      chipGreen: Color.lerp(chipGreen, other.chipGreen, t)!,
    );
  }
}
