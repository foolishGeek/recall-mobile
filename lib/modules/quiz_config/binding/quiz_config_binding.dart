import 'package:get/get.dart';

import '../../../data/repositories/bucket/bucket_repository.dart';
import '../../../data/repositories/node/node_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/quiz/quiz_repository.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/services/billing/tier_service.dart';
import '../../../data/services/sync/sync_status_service.dart';
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
