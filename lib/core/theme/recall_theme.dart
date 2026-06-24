// Recall · theme. Wraps colors + typography into a ThemeData and attaches both
// as ThemeExtensions so any widget can pull them with
// `Theme.of(context).extension<...>()` or the helpers `RecallColors.of(context)`
// / `context.type`.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'recall_colors.dart';
import 'recall_typography.dart';

// Private extension that attaches the real, ink-aware RecallType to the theme.
@immutable
class _RecallTypeExt extends ThemeExtension<_RecallTypeExt> {
  final RecallType data;
  const _RecallTypeExt(this.data);

  @override
  _RecallTypeExt copyWith({RecallType? data}) => _RecallTypeExt(data ?? this.data);

  @override
  _RecallTypeExt lerp(ThemeExtension<_RecallTypeExt>? other, double t) =>
      (t < 0.5 || other is! _RecallTypeExt) ? this : other;
}

extension RecallTypeContextX on BuildContext {
  RecallType get type =>
      Theme.of(this).extension<_RecallTypeExt>()?.data ??
      RecallType.build(ink: RecallColors.of(this).ink);
}

class RecallTheme {
  static ThemeData light() => _build(RecallColors.light);
  static ThemeData dark() => _build(RecallColors.dark);

  static ThemeData _build(RecallColors c) {
    final isDark = c == RecallColors.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final type = RecallType.build(ink: c.ink);

    return base.copyWith(
      scaffoldBackgroundColor: c.canvas,
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
        primary: c.ink,
        onPrimary: c.inkOnInk,
        surface: c.card,
        onSurface: c.ink,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      splashFactory: InkSparkle.splashFactory,
      extensions: [c, _RecallTypeExt(type)],
    );
  }
}
