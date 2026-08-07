// Recall · InitialBinding. The app-wide singletons (Supabase, auth, tier, app
// session) are registered as `permanent` in main() BEFORE runApp so there is no
// async race. This binding registers the data layer — service stubs + every
// repository — as lazy singletons so feature bindings can resolve them.

import 'package:get/get.dart';

import '../../core/theme/theme_service.dart';
import '../../data/local/local_store.dart';
import '../../data/repositories/ai/ai_repository.dart';
import '../../data/repositories/auth/auth_repository.dart';
import '../../data/repositories/bucket/bucket_repository.dart';
import '../../data/repositories/insights/insights_repository.dart';
import '../../data/repositories/node/node_repository.dart';
import '../../data/repositories/notification/notification_repository.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/quiz/quiz_repository.dart';
import '../../data/repositories/review/review_repository.dart';
import '../../data/repositories/stack/stack_repository.dart';
import '../../data/repositories/today/today_repository.dart';
import '../../data/services/ai/ai_service.dart';
import '../../data/services/auth/auth_service.dart';
import '../../data/services/billing/tier_service.dart';
import '../../data/services/metrics/metrics_service.dart';
import '../../data/services/platform/supabase_service.dart';
import '../../data/services/sync/app_session_service.dart';
import '../../data/services/sync/sync_service.dart';
import '../../data/services/sync/sync_status_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    assert(
      Get.isRegistered<SupabaseService>() &&
          Get.isRegistered<AuthService>() &&
          Get.isRegistered<TierService>() &&
          Get.isRegistered<AppSessionService>() &&
          Get.isRegistered<LocalStore>() &&
          Get.isRegistered<SyncStatusService>() &&
          Get.isRegistered<SyncService>(),
      'Core singletons must be registered in main() before runApp.',
    );

    // Theme: eager + permanent so the cached appearance choice (S24) applies on
    // boot before any route builds; reconciled with profiles.theme on Settings.
    Get.put<ThemeService>(ThemeService(Get.find<LocalStore>()),
        permanent: true);

    // Service stubs (filled in S04/S06/S16).
    Get.lazyPut<AiService>(() => AiService(Get.find()), fenix: true);
    Get.lazyPut<MetricsService>(
        () => MetricsService(
              Get.find(),
              Get.find(),
              Get.find(),
              Get.find(),
            ),
        fenix: true);
    // NotificationService is registered as an eager permanent singleton in main()
    // (it self-wires FCM streams on init); not lazy here.

    // Repositories — the only data surface controllers talk to.
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find()), fenix: true);
    Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<BucketRepository>(
        () => BucketRepository(Get.find(), Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<NodeRepository>(
        () => NodeRepository(Get.find(), Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<ReviewRepository>(
        () => ReviewRepository(Get.find(), Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<QuizRepository>(() => QuizRepository(Get.find()), fenix: true);
    Get.lazyPut<StackRepository>(
        () => StackRepository(Get.find(), Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<InsightsRepository>(() => InsightsRepository(Get.find()),
        fenix: true);
    Get.lazyPut<AiRepository>(
        () => AiRepository(Get.find(), Get.find(), Get.find()),
        fenix: true);
    Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find()),
        fenix: true);
    Get.lazyPut<TodayRepository>(() => TodayRepository(Get.find()),
        fenix: true);
  }
}
