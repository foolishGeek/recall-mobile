import 'package:get/get.dart';

import '../controller/ai_chat_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AiChatController(
        Get.find(), // AuthService
        Get.find(), // AiRepository
        Get.find(), // BucketRepository
        Get.find(), // ProfileRepository
        Get.find(), // TierService
      ),
    );
  }
}
