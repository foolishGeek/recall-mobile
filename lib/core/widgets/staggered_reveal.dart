// Recall · StaggeredReveal. The shared card-arrival animation: each item fades
// in + lifts a few px, offset 60ms per index over a 320ms window, driven by a
// single screen-level AnimationController (Insights, and reusable elsewhere).
// Honors reduced motion (renders the child immediately). Block B3 motion tokens.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/recall_motion.dart';

class StaggeredReveal extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;

  /// Per-index delay and per-card animation window (ms).
  final int stepMs;
  final int windowMs;
  final double lift;

  const StaggeredReveal({
    super.key,
    required this.index,
    required this.controller,
    required this.child,
    this.stepMs = 60,
    this.windowMs = 320,
    this.lift = 6,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return child;

    final maxMs = controller.duration?.inMilliseconds ?? (stepMs * 8 + windowMs);
    final startMs = stepMs * index;
    final begin = (startMs / maxMs).clamp(0.0, 1.0);
    final end = ((startMs + windowMs) / maxMs).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end == begin ? 1.0 : end, curve: RecallMotion.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final v = animation.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, lift * (1 - v)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
