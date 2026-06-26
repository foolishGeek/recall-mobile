// Recall · level titles + XP band math. Client-only presentation [D-UI-4]: the
// level *title* is a frozen constant map keyed by `profiles.level` (no DB), and
// LevelBand derives the XP-to-next / progress from (xp, level) using the exact
// curve in [D-ENG-12]. The numbers themselves stay server-authoritative — this
// only formats what the You-tab XP ring shows.

import 'dart:math' as math;

/// Frozen divisor from [D-ENG-12] (mirrors `app_config.level_xp_divisor = 100`).
const int _kLevelXpDivisor = 100;

/// Calm, essay-style level titles keyed by level. Anchored to the design
/// (Level 7 = "Steady reviewer"). Levels beyond the map fall back to the
/// highest title — earned, never gamified.
class LevelTitles {
  const LevelTitles._();

  static const Map<int, String> _titles = {
    1: 'First spark',
    2: 'Curious mind',
    3: 'Note taker',
    4: 'Daily returner',
    5: 'Habit forming',
    6: 'Consistent hand',
    7: 'Steady reviewer',
    8: 'Sharp recall',
    9: 'Deep retainer',
    10: 'Memory builder',
    11: 'Knowledge keeper',
    12: 'Seasoned mind',
    13: 'Master of recall',
    14: 'Memory architect',
    15: 'Living library',
  };

  static const String _topTitle = 'Living library';

  /// The title for [level], clamped to the map (>= 15 → the top title).
  static String forLevel(int level) {
    if (level <= 1) return _titles[1]!;
    return _titles[level] ?? _topTitle;
  }
}

/// The XP band for a level, computed per [D-ENG-12]. `level` is server truth
/// (`profiles.level`); we derive the band edges from it and place `xp` inside.
///
///   threshold(L) = 100·(L−1)²   cap(L) = 100·L²
///   xp_to_next   = cap − xp     progress = (xp − threshold) / (cap − threshold)
class LevelBand {
  final int level;
  final int xp;

  /// XP at the start of this level's band.
  final int threshold;

  /// XP at the start of the next level.
  final int cap;

  /// `cap − xp`, floored at 0.
  final int xpToNext;

  /// 0..1 position of `xp` within the band.
  final double progress;

  const LevelBand._({
    required this.level,
    required this.xp,
    required this.threshold,
    required this.cap,
    required this.xpToNext,
    required this.progress,
  });

  factory LevelBand.fromProfile({required int xp, required int level}) {
    final l = level < 1 ? 1 : level;
    final threshold = _kLevelXpDivisor * (l - 1) * (l - 1);
    final cap = _kLevelXpDivisor * l * l;
    final span = cap - threshold;
    final within = xp - threshold;
    final progress =
        span <= 0 ? 0.0 : (within / span).clamp(0.0, 1.0).toDouble();
    final toNext = cap - xp;
    return LevelBand._(
      level: l,
      xp: xp,
      threshold: threshold,
      cap: cap,
      xpToNext: math.max(0, toNext),
      progress: progress,
    );
  }

  int get nextLevel => level + 1;
}
