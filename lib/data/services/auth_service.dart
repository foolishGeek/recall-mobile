// Recall · AuthService. Thin auth state singleton over Supabase auth. S02 scope:
// session presence (drives AuthGate) + analytics opt-in flag (gates Sentry
// beforeSend). S08: exposes currentUserId, signOut, and profile-backed
// onboardingDone (wired after session appears).

import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService extends GetxService {
  AuthService(this._supabase);

  final SupabaseService _supabase;
  StreamSubscription<AuthState>? _authSub;

  final Rxn<Session> _session = Rxn<Session>();

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

  /// The signed-in user's UUID, or null.
  String? get currentUserId => _supabase.client.auth.currentUser?.id;

  /// Reactive session stream for controllers to listen to sign-in events.
  Rxn<Session> get sessionRx => _session;

  /// Gates Sentry `beforeSend` + telemetry. Real value comes from
  /// `profiles.analytics_opt_in` in S24.
  bool get analyticsOptIn => _analyticsOptIn.value;

  /// Called after profile fetch to sync the gate flag with server truth.
  void setOnboardingDone(bool value) => _onboardingDone.value = value;

  /// Called after profile fetch to sync the analytics flag.
  void setAnalyticsOptIn(bool value) => _analyticsOptIn.value = value;

  Future<void> signOut() async {
    await _supabase.client.auth.signOut();
  }
}
