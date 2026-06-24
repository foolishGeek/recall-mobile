// Recall · typography. Loaded from Google Fonts at runtime.
//
//   final t = RecallType.of(context);
//   Text('Insights', style: t.displayLg.copyWith(color: c.ink));
//
// Conventions:
//   - display* uses Fraunces (editorial serif)
//   - wordmark uses Nunito (used only on Splash / Sign-in / Onboarding / Paywall hero)
//   - body / ui uses Inter
//   - mono uses JetBrains Mono and is ALWAYS used uppercased + tracked
//   - serifItalic is Instrument Serif italic — for the editorial promise

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'recall_colors.dart';

class RecallType {
  // Display / Fraunces
  final TextStyle displayXl; // 64
  final TextStyle displayLg; // 46
  final TextStyle displayMd; // 38
  final TextStyle displaySm; // 32
  final TextStyle headingLg; // 28
  final TextStyle headingMd; // 24
  final TextStyle headingSm; // 20
  final TextStyle numeralLg; // 40 — for hero metrics
  final TextStyle numeralMd; // 28
  final TextStyle numeralSm; // 22

  // Wordmark / Nunito
  final TextStyle wordmark; // 46

  // Editorial promise / Instrument Serif italic
  final TextStyle serifItalic; // 24

  // UI / Inter
  final TextStyle bodyLg; // 16
  final TextStyle body; // 14
  final TextStyle bodySm; // 13
  final TextStyle bodyXs; // 12
  final TextStyle labelLg; // 15  600
  final TextStyle label; // 14  600
  final TextStyle labelSm; // 13  600

  // Mono / JetBrains Mono — caller is responsible for .toUpperCase()
  final TextStyle monoLabel; // 10 · 0.18em tracking
  final TextStyle monoLabelSm; // 9.5
  final TextStyle monoCaption; // 11
  final TextStyle monoNumeral; // 14

  const RecallType._({
    required this.displayXl,
    required this.displayLg,
    required this.displayMd,
    required this.displaySm,
    required this.headingLg,
    required this.headingMd,
    required this.headingSm,
    required this.numeralLg,
    required this.numeralMd,
    required this.numeralSm,
    required this.wordmark,
    required this.serifItalic,
    required this.bodyLg,
    required this.body,
    required this.bodySm,
    required this.bodyXs,
    required this.labelLg,
    required this.label,
    required this.labelSm,
    required this.monoLabel,
    required this.monoLabelSm,
    required this.monoCaption,
    required this.monoNumeral,
  });

  static RecallType build({required Color ink}) {
    TextStyle fr(
      double s, {
      FontWeight w = FontWeight.w500,
      double h = 1.05,
      double ls = -0.01,
    }) =>
        GoogleFonts.fraunces(
          fontSize: s,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          color: ink,
        );

    TextStyle inter(double s, {FontWeight w = FontWeight.w400, double h = 1.5}) =>
        GoogleFonts.inter(fontSize: s, fontWeight: w, height: h, color: ink);

    TextStyle mono(
      double s, {
      double tracking = 0.18,
      FontWeight w = FontWeight.w500,
    }) =>
        GoogleFonts.jetBrainsMono(
          fontSize: s,
          fontWeight: w,
          height: 1.2,
          letterSpacing: s * tracking / 6,
          color: ink,
        );

    return RecallType._(
      displayXl: fr(64, h: 0.98),
      displayLg: fr(46, h: 1.0),
      displayMd: fr(38, h: 1.0),
      displaySm: fr(32, h: 1.05),
      headingLg: fr(28, h: 1.1),
      headingMd: fr(24, h: 1.15),
      headingSm: fr(20, h: 1.2),
      numeralLg: fr(40, h: 1.0, ls: -0.02),
      numeralMd: fr(28, h: 1.0, ls: -0.02),
      numeralSm: fr(22, h: 1.0, ls: -0.02),
      wordmark: GoogleFonts.nunito(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: ink,
        letterSpacing: 0.18,
      ),
      serifItalic: GoogleFonts.instrumentSerif(
        fontSize: 24,
        fontStyle: FontStyle.italic,
        height: 1.22,
        color: ink,
      ),
      bodyLg: inter(16),
      body: inter(14, h: 1.55),
      bodySm: inter(13, h: 1.55),
      bodyXs: inter(12, h: 1.5),
      labelLg: inter(15, w: FontWeight.w600, h: 1.3),
      label: inter(14, w: FontWeight.w600, h: 1.3),
      labelSm: inter(13, w: FontWeight.w600, h: 1.3),
      monoLabel: mono(10),
      monoLabelSm: mono(9.5),
      monoCaption: mono(11, tracking: 0.1),
      monoNumeral: mono(14, tracking: 0, w: FontWeight.w500),
    );
  }

  static RecallType of(BuildContext context) {
    final ink = Theme.of(context).extension<RecallColors>()?.ink ??
        const Color(0xFF111111);
    return build(ink: ink);
  }
}
