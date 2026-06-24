import 'package:get/get.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import '../controller/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OnboardingController(
        Get.find<AuthService>(),
        Get.find<ProfileRepository>(),
        Get.find<NotificationService>(),
      ),
    );
  }
}
