// Recall · TierService. Holds the active subscription tier and exposes a
// TierGate for per-screen gating. S02 stub defaults to free; real resolution
// from `subscriptions` lands in S03/S23.

import 'package:get/get.dart';

import '../../core/gates/tier_gate.dart';

class TierService extends GetxService {
  final Rx<SubscriptionTier> _tier = SubscriptionTier.free.obs;

  SubscriptionTier get tier => _tier.value;
  Rx<SubscriptionTier> get tierRx => _tier;

  TierGate get gate => TierGate(_tier.value);

  void setTier(SubscriptionTier tier) => _tier.value = tier;
}
