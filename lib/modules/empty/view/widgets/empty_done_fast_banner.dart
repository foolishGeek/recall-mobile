// Recall · ephemeral "Done in N min · faster than usual" banner [D-UI-3].

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../data/services/metrics_service.dart';

class EmptyDoneFastBanner extends StatefulWidget {
  final DoneFastBanner banner;

  const EmptyDoneFastBanner({super.key, required this.banner});

  @override
  State<EmptyDoneFastBanner> createState() => _EmptyDoneFastBannerState();
}

class _EmptyDoneFastBannerState extends State<EmptyDoneFastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
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
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

    final text = widget.banner.fasterThanUsual
        ? 'Done in ${widget.banner.minutes} min · faster than usual'
        : 'Done in ${widget.banner.minutes} min';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.grey200),
      ),
      child: Text(
        text,
        style: t.monoCaption.copyWith(color: c.grey600, letterSpacing: 0.04),
      ),
    );

    if (reduceMotion) return chip;

    // Fade in (0–25%), hold (25–75%), fade out (75–100%).
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25,
        ),
      ]).animate(_controller),
      child: chip,
    );
  }
}
