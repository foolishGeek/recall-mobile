import 'package:get/get.dart';

import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/tier_service.dart';
import '../controller/bucket_controller.dart';

class BucketBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BucketController(
          Get.find<AuthService>(),
          Get.find<BucketRepository>(),
          Get.find<NodeRepository>(),
          Get.find<AiRepository>(),
          Get.find<TierService>(),
        ));
  }
}
