// Recall · moon + checkmark illustration with a calm 4s star pulse loop.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/recall_colors.dart';

class EmptyMoonIllustration extends StatefulWidget {
  final double height;

  const EmptyMoonIllustration({super.key, this.height = 140});

  @override
  State<EmptyMoonIllustration> createState() => _EmptyMoonIllustrationState();
}

class _EmptyMoonIllustrationState extends State<EmptyMoonIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (!reduceMotion) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

    final moon = SvgPicture.asset(
      'assets/illustrations/empty-moon-checkmark.svg',
      height: widget.height,
      colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
    );

    if (reduceMotion) return moon;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        // Stars in the SVG sit in the upper field — a gentle whole-illustration
        // breathe reads as star pulse without parsing SVG groups.
        final t = 0.5 + (_pulse.value * 0.5);
        return Opacity(opacity: t, child: child);
      },
      child: moon,
    );
  }
}
