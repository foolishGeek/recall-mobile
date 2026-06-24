// Recall · SplashController. S07: Nike-style kinetic splash — single 2400ms
// timeline drives the word-by-word build, hold, and fade-out. Skippable; honors
// reduced motion. Routes via AuthGate on completion.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/gates/auth_gate.dart';
import '../../../core/theme/recall_motion.dart';
import '../../../data/services/auth_service.dart';

class SplashController extends GetxController
    with GetTickerProviderStateMixin {
  final AuthService _auth = Get.find<AuthService>();

  static const _total = 2400.0;

  late final AnimationController timeline;
  late final AnimationController _skipCtrl;

  // Wordmark: 0–500ms (easeOut, +8px lift)
  late final Animation<double> wordmarkOpacity;
  late final Animation<double> wordmarkSlide;

  // "Forget": 500–900ms (easeOut, +9px lift)
  late final Animation<double> forgetOpacity;
  late final Animation<double> forgetSlide;

  // "forgetting": 900–1300ms (easeOut, +9px lift)
  late final Animation<double> forgettingOpacity;
  late final Animation<double> forgettingSlide;

  // ".": 1300–1600ms (opacity easeOut, scale bubbly)
  late final Animation<double> dotOpacity;
  late final Animation<double> dotScale;

  // Whole-stack fade: 2000–2400ms (easeIn)
  late final Animation<double> fadeOutOpacity;

  // Skip fade: 400ms (easeIn, 1→0)
  late final Animation<double> skipOpacity;

  /// Merged listenable for AnimatedBuilder in the view.
  late final Listenable animation;

  bool _navigated = false;
  bool _skipping = false;
  bool _reducedMotion = false;

  bool get isSkipping => _skipping;

  @override
  void onInit() {
    super.onInit();

    timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    final wc = _phase(0, 500);
    wordmarkOpacity = _fade(wc);
    wordmarkSlide = _lift(wc, 8);

    final fc = _phase(500, 900);
    forgetOpacity = _fade(fc);
    forgetSlide = _lift(fc, 9);

    final fgc = _phase(900, 1300);
    forgettingOpacity = _fade(fgc);
    forgettingSlide = _lift(fgc, 9);

    dotOpacity = _fade(_phase(1300, 1600));
    dotScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: timeline,
      curve: Interval(1300 / _total, 1600 / _total, curve: RecallMotion.bubbly),
    ));

    fadeOutOpacity = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: timeline,
      curve: Interval(2000 / _total, 1.0, curve: RecallMotion.easeIn),
    ));

    timeline.addStatusListener((s) {
      if (s == AnimationStatus.completed) _navigate();
    });

    _skipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    skipOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _skipCtrl, curve: RecallMotion.easeIn),
    );
    _skipCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _navigate();
    });

    animation = Listenable.merge([timeline, _skipCtrl]);
  }

  CurvedAnimation _phase(double startMs, double endMs) => CurvedAnimation(
        parent: timeline,
        curve: Interval(startMs / _total, endMs / _total,
            curve: RecallMotion.easeOut),
      );

  Animation<double> _fade(CurvedAnimation ca) =>
      Tween(begin: 0.0, end: 1.0).animate(ca);

  Animation<double> _lift(CurvedAnimation ca, double px) =>
      Tween(begin: px, end: 0.0).animate(ca);

  @override
  void onReady() {
    super.onReady();
    _reducedMotion =
        MediaQuery.maybeOf(Get.context!)?.disableAnimations ?? false;
    if (_reducedMotion) {
      timeline.value = 2000 / _total;
      Future<void>.delayed(const Duration(milliseconds: 600), _navigate);
    } else {
      timeline.forward();
    }
  }

  void skip() {
    if (_navigated || _skipping) return;
    _skipping = true;
    timeline.stop();
    if (_reducedMotion) {
      _navigate();
    } else {
      _skipCtrl.forward();
    }
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;
    // TODO(analytics): app_opened (gated by analytics_opt_in) [D-OBS-2]
    String route;
    try {
      final gate = AuthGate(
        hasSession: _auth.hasSession,
        onboardingDone: _auth.onboardingDone,
      );
      route = gate.resolvePostSplashRoute();
    } catch (e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'splash'),
      );
      route = Routes.signin;
    }
    Get.offAllNamed(route);
  }

  @override
  void onClose() {
    timeline.dispose();
    _skipCtrl.dispose();
    super.onClose();
  }
}
