import 'package:get/get.dart';

import '../../../data/local/local_store.dart';
import '../../../data/repositories/ai/ai_repository.dart';
import '../../../data/repositories/bucket/bucket_repository.dart';
import '../../../data/repositories/node/node_repository.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/services/billing/tier_service.dart';
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
          Get.find<LocalStore>(),
          Get.find(), // ProfileRepository
        ));
  }
}
