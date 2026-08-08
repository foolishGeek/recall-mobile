// Recall · TierService. Holds the active subscription tier and exposes a
// TierGate for per-screen gating. Resolved from server `subscriptions` +
// `profiles.had_premium` on boot and after entitlement refresh.
// Paywall / WIP / quota denial routing is centralized in [enforce].
// Cache 3: last Profile + Subscription snapshot for fast Settings paint.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/config/ai_policy.dart';
import '../../../core/config/ai_policy_config.dart';
import '../../../core/config/app_limits.dart';
import '../../../core/config/limits_config.dart';
import '../../../core/gates/feature.dart';
import '../../../core/gates/resolve_tier.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/load_cache_ttl.dart';
import '../../../modules/quiz_home/view/widgets/quiz_in_progress_sheet.dart';
import '../../models/models.dart';
import '../../repositories/profile/profile_repository.dart';

export '../../../core/gates/resolve_tier.dart' show resolveSubscriptionTier;

/// Last entitlement objects kept in RAM for Settings (and similar) fast paint.
class EntitlementSnapshot {
  final Profile? profile;
  final Subscription? subscription;
  final DateTime fetchedAt;

  const EntitlementSnapshot({
    required this.profile,
    required this.subscription,
    required this.fetchedAt,
  });

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) <= kEntitlementMemoryTtl;
}

class TierService extends GetxService {
  final Rx<SubscriptionTier> _tier = SubscriptionTier.free.obs;

  EntitlementSnapshot? _entitlement;

  SubscriptionTier get tier => _tier.value;
  Rx<SubscriptionTier> get tierRx => _tier;

  /// Cache 3 — last profile/subscription from splash / refresh / Settings.
  EntitlementSnapshot? get entitlementSnapshot => _entitlement;

  EntitlementSnapshot? get freshEntitlement {
    final snap = _entitlement;
    if (snap == null || !snap.isFresh) return null;
    return snap;
  }

  /// Touches tier, limits and AI-policy Rx so Obx rebuilds on any flip.
  TierGate get gate {
    final limits = Get.isRegistered<LimitsConfig>()
        ? Get.find<LimitsConfig>().snapshot.value
        : AppLimits.canon;
    final policy = Get.isRegistered<AiPolicyConfig>()
        ? Get.find<AiPolicyConfig>().snapshot.value
        : AiPolicy.canon;
    return TierGate(_tier.value, limits, policy: policy);
  }

  bool get isPremium => _tier.value == SubscriptionTier.premium;
  bool get isDowngraded => _tier.value == SubscriptionTier.downgraded;
  bool get isFree => _tier.value == SubscriptionTier.free;

  void setTier(SubscriptionTier tier) => _tier.value = tier;

  void applyEntitlement({
    Subscription? subscription,
    Profile? profile,
    bool touchCache = true,
  }) {
    setTier(resolveSubscriptionTier(subscription, profile));
    if (touchCache) {
      _entitlement = EntitlementSnapshot(
        profile: profile,
        subscription: subscription,
        fetchedAt: DateTime.now(),
      );
    }
  }

  /// Keep Cache 3 aligned after a successful prefs write without re-fetching
  /// subscription.
  void updateCachedProfile(Profile profile) {
    final prev = _entitlement;
    _entitlement = EntitlementSnapshot(
      profile: profile,
      subscription: prev?.subscription,
      fetchedAt: DateTime.now(),
    );
    // Tier may depend on had_premium / etc. — re-resolve if we have both.
    if (prev?.subscription != null || profile.hadPremium) {
      setTier(resolveSubscriptionTier(prev?.subscription, profile));
    }
  }

  void clearEntitlementCache() {
    _entitlement = null;
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
    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    final r = await profiles.refreshEntitlement(userId);
    applyEntitlement(subscription: r.subscription, profile: r.profile);
    if (sw != null) {
      debugPrint(
        '[perf] refreshEntitlement ${sw.elapsedMilliseconds}ms',
      );
    }
    return _tier.value;
  }
}
