// Recall · InitialBinding. The app-wide singletons (Supabase, auth, tier) are
// registered as `permanent` in main() BEFORE runApp so there is no async race
// (sprint §bootstrap). This binding is idempotent — it only guarantees the
// route scope can resolve them; it never creates the Supabase client.

import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/tier_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    assert(
      Get.isRegistered<SupabaseService>() &&
          Get.isRegistered<AuthService>() &&
          Get.isRegistered<TierService>(),
      'Core singletons must be registered in main() before runApp.',
    );
  }
}
