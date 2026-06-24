// Recall · SplashView. S07: Nike-style kinetic type — "Recall" in Nunito first,
// then tagline builds word-by-word in Instrument Serif italic beneath it.
// Tap anywhere to skip. No logomark, no color, strictly monochrome.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_typography.dart';
import '../controller/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return GestureDetector(
      onTap: controller.skip,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: AnimatedBuilder(
          animation: controller.animation,
          builder: (context, _) {
            final stackOpacity = controller.isSkipping
                ? controller.skipOpacity.value
                : controller.fadeOutOpacity.value;

            return Center(
              child: Opacity(
                opacity: stackOpacity.clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedWord(
                      text: 'Recall',
                      style: t.wordmark,
                      opacity: controller.wordmarkOpacity,
                      slide: controller.wordmarkSlide,
                      isSkipping: controller.isSkipping,
                    ),
                    const SizedBox(height: 26),
                    _Tagline(controller: controller, style: t.serifItalic),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  final SplashController controller;
  final TextStyle style;

  const _Tagline({required this.controller, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        _AnimatedWord(
          text: 'Forget',
          style: style,
          opacity: controller.forgetOpacity,
          slide: controller.forgetSlide,
          isSkipping: controller.isSkipping,
        ),
        SizedBox(width: (style.fontSize ?? 24) * 0.3),
        _AnimatedWord(
          text: 'forgetting',
          style: style,
          opacity: controller.forgettingOpacity,
          slide: controller.forgettingSlide,
          isSkipping: controller.isSkipping,
        ),
        _AnimatedDot(
          style: style,
          opacity: controller.dotOpacity,
          scale: controller.dotScale,
          isSkipping: controller.isSkipping,
        ),
      ],
    );
  }
}

class _AnimatedWord extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Animation<double> opacity;
  final Animation<double> slide;
  final bool isSkipping;

  const _AnimatedWord({
    required this.text,
    required this.style,
    required this.opacity,
    required this.slide,
    required this.isSkipping,
  });

  @override
  Widget build(BuildContext context) {
    final o = isSkipping ? 1.0 : opacity.value.clamp(0.0, 1.0);
    final s = isSkipping ? 0.0 : slide.value;
    return Opacity(
      opacity: o,
      child: Transform.translate(
        offset: Offset(0, s),
        child: Text(text, style: style),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final TextStyle style;
  final Animation<double> opacity;
  final Animation<double> scale;
  final bool isSkipping;

  const _AnimatedDot({
    required this.style,
    required this.opacity,
    required this.scale,
    required this.isSkipping,
  });

  @override
  Widget build(BuildContext context) {
    final o = isSkipping ? 1.0 : opacity.value.clamp(0.0, 1.0);
    final s = isSkipping ? 1.0 : scale.value;
    return Opacity(
      opacity: o,
      child: Transform.scale(
        scale: s,
        alignment: Alignment.bottomCenter,
        child: Text('.', style: style),
      ),
    );
  }
}
