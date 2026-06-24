// Recall · auth gate. Pure routing decision for splash → sign-in | onboarding |
// today (sprint S02 §5). No I/O — fed by AuthService state.

import '../../app/routes/app_routes.dart';

class AuthGate {
  final bool hasSession;
  final bool onboardingDone;

  const AuthGate({this.hasSession = false, this.onboardingDone = false});

  /// no session → /signin · session + !onboarding_done → /onboarding · else /today.
  String resolvePostSplashRoute() {
    if (!hasSession) return Routes.signin;
    if (!onboardingDone) return Routes.onboarding;
    return Routes.today;
  }
}
