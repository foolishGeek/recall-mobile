// Recall · SigninController. S08: orchestrates Apple/Google/magic-link sign-in.
// Reactive state drives the view (idle → loading → sent | error). On session,
// fetches profile and routes via AuthGate. No business logic — just auth I/O
// and UI state transitions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/gates/auth_gate.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';

enum SigninState { idle, loading, sent, error }

class SigninController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final ProfileRepository _profileRepo = Get.find<ProfileRepository>();
  final AuthService _auth = Get.find<AuthService>();

  final emailController = TextEditingController();
  final Rx<SigninState> state = SigninState.idle.obs;
  final RxnString sentEmail = RxnString();
  final RxnString errorText = RxnString();
  final RxInt resendCooldown = 0.obs;

  Timer? _cooldownTimer;
  Worker? _sessionWorker;
  bool _routing = false;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_auth.sessionRx, _onSessionChanged);
  }

  @override
  void onClose() {
    emailController.dispose();
    _cooldownTimer?.cancel();
    _sessionWorker?.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Intent methods
  // ---------------------------------------------------------------------------

  Future<void> onContinueWithApple() async {
    if (state.value == SigninState.loading) return;
    state.value = SigninState.loading;
    errorText.value = null;
    // TODO(analytics): signin_started { provider: apple } [D-OBS-2]

    try {
      final response = await _authRepo.signInWithApple();
      if (response == null) {
        state.value = SigninState.idle;
        return;
      }
      // Session change will trigger _onSessionChanged via the worker.
    } on RepoException catch (e, st) {
      _handleAuthError(e, st, 'apple');
    }
  }

  Future<void> onContinueWithGoogle() async {
    if (state.value == SigninState.loading) return;
    state.value = SigninState.loading;
    errorText.value = null;
    // TODO(analytics): signin_started { provider: google } [D-OBS-2]

    try {
      final response = await _authRepo.signInWithGoogle();
      if (response == null) {
        state.value = SigninState.idle;
        return;
      }
    } on RepoException catch (e, st) {
      _handleAuthError(e, st, 'google');
    }
  }

  Future<void> onSendMagicLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      errorText.value = 'Enter a valid email address';
      state.value = SigninState.error;
      return;
    }
    if (state.value == SigninState.loading) return;
    state.value = SigninState.loading;
    errorText.value = null;
    // TODO(analytics): signin_started { provider: magic_link } [D-OBS-2]

    try {
      await _authRepo.signInWithMagicLink(email);
      sentEmail.value = email;
      state.value = SigninState.sent;
      _startResendCooldown();
    } on RepoException catch (e, st) {
      _handleAuthError(e, st, 'magic_link');
    }
  }

  Future<void> onResendMagicLink() async {
    if (resendCooldown.value > 0 || state.value == SigninState.loading) return;
    final email = sentEmail.value;
    if (email == null || email.isEmpty) return;

    state.value = SigninState.loading;
    errorText.value = null;

    try {
      await _authRepo.signInWithMagicLink(email);
      state.value = SigninState.sent;
      _startResendCooldown();
    } on RepoException catch (e, st) {
      _handleAuthError(e, st, 'magic_link');
    }
  }

  void onUseDifferentEmail() {
    sentEmail.value = null;
    errorText.value = null;
    state.value = SigninState.idle;
    _cooldownTimer?.cancel();
    resendCooldown.value = 0;
  }

  Future<void> onOpenTerms() async {
    const url = 'https://recall.app/terms';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> onOpenPrivacy() async {
    const url = 'https://recall.app/privacy';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ---------------------------------------------------------------------------
  // Session routing
  // ---------------------------------------------------------------------------

  void _onSessionChanged(dynamic session) {
    if (session == null || _routing) return;
    _routing = true;
    // TODO(analytics): signin_succeeded [D-OBS-2]
    _resolveRouteAfterSignIn();
  }

  Future<void> _resolveRouteAfterSignIn() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      _routing = false;
      return;
    }

    try {
      final profile = await _profileRepo.fetchProfile(userId);
      final onboardingDone = profile?.onboardingDone ?? false;
      _auth.setOnboardingDone(onboardingDone);

      // Fire-and-forget: update timezone/locale from device if defaults.
      _patchDeviceMetadata(userId, profile?.timezone);
    } catch (e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'signin'),
      );
    }

    final gate = AuthGate(
      hasSession: _auth.hasSession,
      onboardingDone: _auth.onboardingDone,
    );
    Get.offAllNamed(gate.resolvePostSplashRoute());
  }

  /// Per S08: "mobile UPDATE profiles SET timezone/locale if trigger metadata
  /// was absent". The handle_new_user trigger defaults timezone='UTC' and
  /// locale='en'; if those are still the defaults, patch with device values.
  Future<void> _patchDeviceMetadata(
    String userId,
    String? currentTimezone,
  ) async {
    try {
      final changes = <String, dynamic>{};

      if (currentTimezone == null || currentTimezone == 'UTC') {
        changes['timezone'] = DateTime.now().timeZoneName;
      }

      final deviceLocale = Get.deviceLocale;
      if (deviceLocale != null) {
        changes['locale'] = deviceLocale.languageCode;
      }

      if (changes.isNotEmpty) {
        await _profileRepo.updatePreferences(userId, changes);
      }
    } catch (_) {
      // Best-effort; don't block sign-in flow.
    }
  }

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  void _handleAuthError(RepoException e, StackTrace st, String provider) {
    // TODO(analytics): signin_failed { provider, error_code } [D-OBS-2]
    if (e.isOffline) {
      errorText.value = 'Couldn\'t reach the server — try again';
    } else {
      errorText.value = 'Couldn\'t reach the server — try again';
    }
    state.value = SigninState.error;

    Sentry.captureException(
      e.cause ?? e,
      stackTrace: e.causeStackTrace ?? st,
      withScope: (scope) {
        scope.setTag('feature', 'signin');
        scope.setTag('provider', provider);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Resend cooldown
  // ---------------------------------------------------------------------------

  void _startResendCooldown() {
    resendCooldown.value = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendCooldown.value--;
      if (resendCooldown.value <= 0) {
        timer.cancel();
      }
    });
  }
}
