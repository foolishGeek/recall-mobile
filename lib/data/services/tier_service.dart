// Recall · TierService. Holds the active subscription tier and exposes a
// TierGate for per-screen gating. Resolved from server `subscriptions` +
// `profiles.had_premium` on boot and after entitlement refresh.

import 'package:get/get.dart';

import '../../core/gates/tier_gate.dart';
import '../models/models.dart';
import '../repositories/profile_repository.dart';

/// App-side tier: DB stores `free`/`premium`; downgraded = free + had_premium.
SubscriptionTier resolveSubscriptionTier(
  Subscription? subscription,
  Profile? profile,
) {
  if (subscription?.tier == SubscriptionTier.premium) {
    return SubscriptionTier.premium;
  }
  if (profile?.hadPremium == true) return SubscriptionTier.downgraded;
  return SubscriptionTier.free;
}

class TierService extends GetxService {
  final Rx<SubscriptionTier> _tier = SubscriptionTier.free.obs;

  SubscriptionTier get tier => _tier.value;
  Rx<SubscriptionTier> get tierRx => _tier;

  TierGate get gate => TierGate(_tier.value);

  bool get isPremium => _tier.value == SubscriptionTier.premium;
  bool get isDowngraded => _tier.value == SubscriptionTier.downgraded;
  bool get isFree => _tier.value == SubscriptionTier.free;

  void setTier(SubscriptionTier tier) => _tier.value = tier;

  void applyEntitlement({Subscription? subscription, Profile? profile}) {
    setTier(resolveSubscriptionTier(subscription, profile));
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
