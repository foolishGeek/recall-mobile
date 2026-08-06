// Recall · TierService. Holds the active subscription tier and exposes a
// TierGate for per-screen gating. Resolved from server `subscriptions` +
// `profiles.had_premium` on boot and after entitlement refresh.
// Paywall / WIP / quota denial routing is centralized in [enforce].

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_limits.dart';
import '../../../core/config/limits_config.dart';
import '../../../core/gates/feature.dart';
import '../../../core/gates/resolve_tier.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../modules/quiz_home/view/widgets/quiz_in_progress_sheet.dart';
import '../../models/models.dart';
import '../../repositories/profile/profile_repository.dart';

export '../../../core/gates/resolve_tier.dart' show resolveSubscriptionTier;

class TierService extends GetxService {
  final Rx<SubscriptionTier> _tier = SubscriptionTier.free.obs;

  SubscriptionTier get tier => _tier.value;
  Rx<SubscriptionTier> get tierRx => _tier;

  /// Touches both tier and limits Rx so Obx rebuilds on either flip.
  TierGate get gate {
    final limits = Get.isRegistered<LimitsConfig>()
        ? Get.find<LimitsConfig>().snapshot.value
        : AppLimits.canon;
    return TierGate(_tier.value, limits);
  }

  bool get isPremium => _tier.value == SubscriptionTier.premium;
  bool get isDowngraded => _tier.value == SubscriptionTier.downgraded;
  bool get isFree => _tier.value == SubscriptionTier.free;

  void setTier(SubscriptionTier tier) => _tier.value = tier;

  void applyEntitlement({Subscription? subscription, Profile? profile}) {
    setTier(resolveSubscriptionTier(subscription, profile));
  }

  /// Opens the paywall unless `limits_profile=relaxed` (temporary free).
  void openPaywall() {
    if (gate.suppressPaywall) return;
    Get.toNamed(Routes.paywall);
  }

  /// Single denial router: paywall, quiz WIP sheet, or quota (caller shows copy).
  /// Returns true when the feature is allowed.
  bool enforce(Feature feature, {int used = 0}) {
    final result = gate.access(feature, used: used);
    if (result.allowed) return true;
    switch (result.denial) {
      case AccessDenial.wip:
        QuizInProgressSheet.show();
      case AccessDenial.paywall:
        openPaywall();
      case AccessDenial.quota:
      case null:
        break;
    }
    return false;
  }

  /// Re-reads server-authoritative entitlement (subscription + had_premium).
  Future<SubscriptionTier> refreshFromServer(
    ProfileRepository profiles,
    String userId,
  ) async {
    final r = await profiles.refreshEntitlement(userId);
    applyEntitlement(subscription: r.subscription, profile: r.profile);
    return _tier.value;
  }
}
