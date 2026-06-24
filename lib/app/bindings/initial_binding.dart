// Recall · InitialBinding. The app-wide singletons (Supabase, auth, tier, app
// session) are registered as `permanent` in main() BEFORE runApp so there is no
// async race. This binding registers the data layer — service stubs + every
// repository — as lazy singletons so feature bindings can resolve them.

import 'package:get/get.dart';

import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/bucket_repository.dart';
import '../../data/repositories/insights_repository.dart';
import '../../data/repositories/node_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/stack_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/app_session_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/heat_service.dart';
import '../../data/services/metrics_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/tier_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    assert(
      Get.isRegistered<SupabaseService>() &&
          Get.isRegistered<AuthService>() &&
          Get.isRegistered<TierService>() &&
          Get.isRegistered<AppSessionService>(),
      'Core singletons must be registered in main() before runApp.',
    );

    // Service stubs (filled in S04/S06/S16).
    Get.lazyPut<AiService>(() => AiService(Get.find()), fenix: true);
    Get.lazyPut<MetricsService>(() => MetricsService(), fenix: true);
    Get.lazyPut<HeatService>(() => HeatService(), fenix: true);
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);

    // Repositories — the only data surface controllers talk to.
    Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(Get.find()), fenix: true);
    Get.lazyPut<BucketRepository>(
        () => BucketRepository(Get.find()), fenix: true);
    Get.lazyPut<NodeRepository>(() => NodeRepository(Get.find()), fenix: true);
    Get.lazyPut<ReviewRepository>(
        () => ReviewRepository(Get.find()), fenix: true);
    Get.lazyPut<QuizRepository>(() => QuizRepository(Get.find()), fenix: true);
    Get.lazyPut<StackRepository>(
        () => StackRepository(Get.find()), fenix: true);
    Get.lazyPut<InsightsRepository>(
        () => InsightsRepository(Get.find()), fenix: true);
    Get.lazyPut<AiRepository>(
        () => AiRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find()), fenix: true);
  }
}
