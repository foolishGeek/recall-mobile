// Recall · SplashController. S02 plumbing: hold briefly, then route via
// AuthGate. The full kinetic splash animation lands in S07.

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/gates/auth_gate.dart';
import '../../../data/services/auth_service.dart';

class SplashController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  @override
  void onReady() {
    super.onReady();
    _resolve();
  }

  Future<void> _resolve() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    String route;
    try {
      final gate = AuthGate(
        hasSession: _auth.hasSession,
        onboardingDone: _auth.onboardingDone,
      );
      route = gate.resolvePostSplashRoute();
    } catch (_) {
      route = Routes.signin;
    }
    Get.offAllNamed(route);
  }
}
