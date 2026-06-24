// Recall · AuthService. Thin auth state singleton over Supabase auth. S02 scope:
// session presence (drives AuthGate) + analytics opt-in flag (gates Sentry
// beforeSend). Profile-backed `onboardingDone` + opt-in land in S03.

import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService extends GetxService {
  AuthService(this._supabase);

  final SupabaseService _supabase;
  StreamSubscription<AuthState>? _authSub;

  final Rxn<Session> _session = Rxn<Session>();

  // Stubbed until S03 wires the cached profile.
  final RxBool _onboardingDone = false.obs;
  final RxBool _analyticsOptIn = true.obs;

  @override
  void onInit() {
    super.onInit();
    _session.value = _supabase.client.auth.currentSession;
    _authSub = _supabase.client.auth.onAuthStateChange.listen((state) {
      _session.value = state.session;
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  bool get hasSession => _session.value != null;
  bool get onboardingDone => _onboardingDone.value;

  /// Gates Sentry `beforeSend` + telemetry. Real value comes from
  /// `profiles.analytics_opt_in` in S24.
  bool get analyticsOptIn => _analyticsOptIn.value;
}
