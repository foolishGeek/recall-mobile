// Recall · shape. Frozen corner radii from design-tokens.md §3. Shared widgets
// pull these instead of hard-coding radius numbers.

import 'package:flutter/widgets.dart';

class RecallShape {
  const RecallShape._();

  static const double radiusSm = 10; // chip, segmented
  static const double radiusMd = 16; // buttons, small cards
  static const double radiusLg = 20; // list cards
  static const double radiusXl = 24; // hero cards
  static const double radiusPill = 999;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));
}
