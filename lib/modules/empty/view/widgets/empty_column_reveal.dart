// Recall · EmptyColumnReveal. Center column mount: 420ms fade + 12px Y.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_motion.dart';

class EmptyColumnReveal extends StatefulWidget {
  final Widget child;

  const EmptyColumnReveal({super.key, required this.child});

  @override
  State<EmptyColumnReveal> createState() => _EmptyColumnRevealState();
}

class _EmptyColumnRevealState extends State<EmptyColumnReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: RecallMotion.slow);
    _progress = CurvedAnimation(parent: _controller, curve: RecallMotion.easeOut);

    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, child) {
        final v = _progress.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
