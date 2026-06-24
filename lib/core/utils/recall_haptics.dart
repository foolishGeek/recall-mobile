// Recall · haptics map (design-tokens §6 / Block B3). One place so every screen
// uses the same feedback for the same intent.

import 'package:flutter/services.dart';

class RecallHaptics {
  const RecallHaptics._();

  /// Card swipe / chip select.
  static void light() => HapticFeedback.lightImpact();

  /// Good / Easy rating, paywall purchase intent.
  static void medium() => HapticFeedback.mediumImpact();

  /// Stack complete, delete-account confirm (single).
  static void heavy() => HapticFeedback.heavyImpact();

  /// Forgot rating, toggles, filters, most row taps.
  static void selection() => HapticFeedback.selectionClick();
}
