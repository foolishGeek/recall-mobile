import 'package:get/get.dart';

import '../controller/paywall_controller.dart';

class PaywallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PaywallController(
        Get.find(), // RevenueCatService
        Get.find(), // ProfileRepository
        Get.find(), // TierService
        Get.find(), // AuthService
      ),
    );
  }
}
