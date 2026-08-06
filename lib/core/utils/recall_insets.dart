// Recall · system inset helpers. Android 15+ (targetSdk 35+) always draws the
// window edge-to-edge, so anything anchored to the bottom of the screen has to
// pay the navigation inset itself. RecallScaffold deliberately uses
// SafeArea(bottom: false) so the tab bar owns that inset — every other
// bottom-anchored surface adds it here.
//
//   padding: const EdgeInsets.fromLTRB(16, 14, 16, 22).bottomSafe(context)

import 'package:flutter/material.dart';

extension RecallInsets on BuildContext {
  /// Height of the system navigation bar / gesture handle.
  ///
  /// This is `padding`, not `viewPadding`: it collapses to zero while the
  /// keyboard is open, so composers sit flush on the keyboard instead of
  /// floating a nav-bar's height above it.
  double get bottomInset => MediaQuery.of(this).padding.bottom;

  /// Height of the status bar.
  double get topInset => MediaQuery.of(this).padding.top;
}

extension RecallSafeEdgeInsets on EdgeInsets {
  /// This padding grown by the system bottom inset.
  EdgeInsets bottomSafe(BuildContext context) =>
      copyWith(bottom: bottom + context.bottomInset);
}
