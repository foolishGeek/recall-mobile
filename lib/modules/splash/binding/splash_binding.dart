import 'package:get/get.dart';

import '../controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager put — SplashView is static (no controller refs in build), so lazyPut
    // would never instantiate and onReady would never route away.
    Get.put(SplashController());
  }
}
