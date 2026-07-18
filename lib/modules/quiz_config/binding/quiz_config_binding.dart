import 'package:get/get.dart';

import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../controller/quiz_config_controller.dart';

class QuizConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizConfigController(
          Get.find<AuthService>(),
          Get.find<QuizRepository>(),
          Get.find<BucketRepository>(),
          Get.find<NodeRepository>(),
          Get.find<ProfileRepository>(),
          Get.find<TierService>(),
          Get.find<SyncStatusService>(),
        ));
  }
}
