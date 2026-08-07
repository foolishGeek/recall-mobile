// Shared stagger forward / reduced-motion skip for tab reveal animations.

import 'dart:ui';

import 'package:flutter/animation.dart';

void runStagger(AnimationController controller) {
  final reduceMotion =
      PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
  if (reduceMotion) {
    controller.value = 1.0;
    return;
  }
  controller.forward(from: 0);
}
