import 'package:get/get.dart';

import '../../../data/repositories/ai/ai_repository.dart';
import '../../../data/repositories/node/node_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/services/billing/tier_service.dart';
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
