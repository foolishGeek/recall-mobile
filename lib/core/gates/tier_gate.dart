// Recall · tier gate. Subscription gating — native free, premium, downgraded
// (sprint S02 §5 / Block B5). Pure logic; consumed by feature sprints.

enum SubscriptionTier { free, premium, downgraded }

class TierGate {
  final SubscriptionTier tier;

  const TierGate(this.tier);

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isDowngraded => tier == SubscriptionTier.downgraded;
  bool get isFree => tier == SubscriptionTier.free;

  /// Quiz tab blocked for free and downgraded (PRO lock).
  bool get quizBlocked => !isPremium;

  /// AI features disabled when downgraded.
  bool get aiDisabled => isDowngraded;

  /// AI quota lock when a free user has exhausted monthly requests.
  bool aiQuotaExhausted({required int requestsUsed, int limit = 50}) =>
      isFree && requestsUsed >= limit;

  /// Max writable/active buckets: 2 free, unlimited premium, first 3 downgraded.
  int get maxActiveBuckets {
    switch (tier) {
      case SubscriptionTier.premium:
        return 999;
      case SubscriptionTier.downgraded:
        return 3;
      case SubscriptionTier.free:
        return 2;
    }
  }

  /// Cards per generated stack: 8 free/downgraded, 12 premium [D-ENG-3].
  int get cardsPerStack => isPremium ? 12 : 8;

  /// Bucket index is read-only when downgraded and index >= 3.
  bool isBucketReadOnly(int bucketIndex) => isDowngraded && bucketIndex >= 3;

  /// Show the PRO lock on the add-bucket FAB: free at 2, downgraded at 3.
  bool showBucketFabLock({required int currentBucketCount}) {
    if (isFree) return currentBucketCount >= 2;
    if (isDowngraded) return currentBucketCount >= 3;
    return false;
  }

  /// Node AI overview: 2/month free, unlimited premium, blocked downgraded.
  bool get aiOverviewBlocked => isDowngraded;

  bool aiOverviewQuotaExhausted({required int overviewsUsed, int limit = 2}) =>
      isFree && overviewsUsed >= limit;
}
