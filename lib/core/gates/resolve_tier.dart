// App-side tier: DB stores `free`/`premium`; downgraded = free + had_premium.

import '../../data/models/models.dart';

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
