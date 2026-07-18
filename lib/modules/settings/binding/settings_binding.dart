import 'package:get/get.dart';

import '../controller/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(
        Get.find(), // ProfileRepository
        Get.find(), // AuthService
        Get.find(), // RevenueCatService
        Get.find(), // TierService
        Get.find(), // ThemeService
        Get.find(), // SyncStatusService
        Get.find(), // NotificationService
      ),
    );
  }
}
