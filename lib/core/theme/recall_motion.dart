// Recall · motion. Centralized durations + curves so every screen breathes the
// same way. Frozen tokens — Block B3. Use these instead of magic numbers.

import 'package:flutter/animation.dart';

class RecallMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 180); // press-down
  static const Duration normal = Duration(milliseconds: 320); // most transitions
  static const Duration slow = Duration(milliseconds: 420); // hero reveals
  static const Duration tabSwap = Duration(milliseconds: 280);
  static const Duration shimmer = Duration(milliseconds: 1400); // skeletons

  // Curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;

  // Bubbly — POSITIVE moments only (Good/Easy, level up, completion, CTA).
  // A calm overshoot, not a bounce.
  static const Curve bubbly = Cubic(0.34, 1.42, 0.64, 1.0);

  // Quiet — negative or warning moments (Forgot).
  static const Curve quiet = Cubic(0.4, 0, 0.2, 1);

  /// Onboarding panel horizontal slide — slow ease-out per Recall Onboarding.dc.html.
  static const Duration pageSlide = Duration(milliseconds: 460);
  static const Curve pageEase = Cubic(0.22, 0.61, 0.36, 1);

  /// CTA press scale duration (bubbly spring on positive paths).
  static const Duration ctaPress = Duration(milliseconds: 360);

  // Spring — chip press, success, level-up (Block B3: stiffness 220, damping 24).
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 24,
  );
}
