import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/theme/recall_motion.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';

class OnboardingController extends BaseController {
  OnboardingController(
    this._auth,
    this._profiles,
    this._notifications,
  );

  final AuthService _auth;
  final ProfileRepository _profiles;
  final NotificationService _notifications;

  static const _pageCount = 3;

  final pageController = PageController();
  final currentPage = 0.obs;
  final dropEnabled = true.obs;
  final isCompleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    setSuccess();
    _guardSession();
    // TODO(analytics): onboarding_started (gated by analytics_opt_in) [D-OBS-2]
  }

  @override
  void onReady() {
    super.onReady();
    _guardSession();
    if (_auth.onboardingDone) {
      Get.offAllNamed(Routes.today);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  /// Onboarding requires a session (AuthGate). Deep links / expired sessions
  /// bounce to sign-in before any profile write or bucket flow.
  void _guardSession() {
    if (!_auth.hasSession) {
      Get.offAllNamed(Routes.signin);
    }
  }

  void onPageChanged(int index) {
    if (index == currentPage.value) return;
    RecallHaptics.selection();
    currentPage.value = index;
  }

  void goToPage(int index) {
    if (index < 0 || index >= _pageCount) return;
    if (index == currentPage.value) return;
    pageController.animateToPage(
      index,
      duration: RecallMotion.pageSlide,
      curve: RecallMotion.pageEase,
    );
  }

  void onPrimaryPressed() {
    if (isCompleting.value) return;
    if (!_auth.hasSession) {
      Get.offAllNamed(Routes.signin);
      return;
    }
    final page = currentPage.value;
    if (page < 2) {
      goToPage(page + 1);
      return;
    }
    _completeOnboarding(
      route: Routes.nodeAdd,
      requestPush: true,
    );
  }

  void skip() {
    if (isCompleting.value) return;
    if (!_auth.hasSession) {
      Get.offAllNamed(Routes.signin);
      return;
    }
    _completeOnboarding(
      route: Routes.today,
      requestPush: false,
    );
  }

  void setDropEnabled(bool value) => dropEnabled.value = value;

  String get primaryLabel {
    switch (currentPage.value) {
      case 0:
        return 'Continue';
      case 1:
        return 'Continue';
      default:
        return 'Make my first bucket';
    }
  }

  bool get showSkip => currentPage.value < 2;

  Future<void> _completeOnboarding({
    required String route,
    required bool requestPush,
  }) async {
    if (isCompleting.value) return;
    if (!_auth.hasSession) {
      Get.offAllNamed(Routes.signin);
      return;
    }

    isCompleting.value = true;

    final userId = _auth.currentUserId;
    if (userId == null) {
      Get.offAllNamed(Routes.signin);
      return;
    }

    var pushOptIn = false;
    const dropFrequency = 'daily';

    if (requestPush && dropEnabled.value) {
      try {
        final granted = await _notifications.requestPushPermission();
        if (granted) {
          pushOptIn = true;
          await _notifications.registerDeviceToken();
        }
      } catch (e, st) {
        await Sentry.captureException(
          e,
          stackTrace: st,
          withScope: (scope) => scope.setTag('feature', 'onboarding'),
        );
      }
    }

    try {
      await _profiles.ensureProfile();
      await _profiles.updatePreferencesResilient(
        userId,
        {
          'onboarding_done': true,
          'push_opt_in': pushOptIn,
          'drop_frequency': dropFrequency,
        },
      );
    } catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'onboarding'),
      );
    }

    _auth.setOnboardingDone(true);
    // TODO(analytics): onboarding_completed, push_opt_in_set { value: pushOptIn } [D-OBS-2]
    Get.offAllNamed(Routes.today);
    if (route == Routes.nodeAdd) {
      Get.toNamed(Routes.nodeAdd);
    }
  }
}
