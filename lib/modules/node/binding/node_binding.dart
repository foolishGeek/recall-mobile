import 'package:get/get.dart';

import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/tier_service.dart';
import '../controller/node_controller.dart';

class NodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NodeController(
          Get.find<AuthService>(),
          Get.find<NodeRepository>(),
          Get.find<AiRepository>(),
          Get.find<ProfileRepository>(),
          Get.find<TierService>(),
        ));
  }
}
