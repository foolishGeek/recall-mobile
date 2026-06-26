import 'package:get/get.dart';

import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/tier_service.dart';
import '../controller/quiz_home_controller.dart';

class QuizHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizHomeController(
          Get.find<AuthService>(),
          Get.find<QuizRepository>(),
          Get.find<TierService>(),
        ));
  }
}
