import 'package:get/get.dart';

import '../../../data/local/local_store.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/tier_service.dart';
import '../controller/node_add_controller.dart';

class NodeAddBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NodeAddController(
          Get.find<AuthService>(),
          Get.find<NodeRepository>(),
          Get.find<AiRepository>(),
          Get.find<BucketRepository>(),
          Get.find<TierService>(),
          Get.find<LocalStore>(),
        ));
  }
}
