// Recall · tier gate. Subscription gating — native free, premium, downgraded
// (sprint S02 §5 / Block B5). Free numeric caps come from [LimitsConfig]
// when registered; otherwise canon defaults.

import 'package:get/get.dart';

import '../config/limits_config.dart';

enum SubscriptionTier { free, premium, downgraded }

class TierGate {
  final SubscriptionTier tier;

  const TierGate(this.tier);

  LimitsConfig? get _limitsOrNull =>
      Get.isRegistered<LimitsConfig>() ? Get.find<LimitsConfig>() : null;

  int get _aiQuota =>
      _limitsOrNull?.aiQuotaFreeMonthly ?? LimitsConfig.canonAiQuota;
  int get _aiOverviews =>
      _limitsOrNull?.aiOverviewFreeMonthly ?? LimitsConfig.canonAiOverviews;
  int get _buckets =>
      _limitsOrNull?.bucketsFreeWritable ?? LimitsConfig.canonBuckets;
  int get _sessionSize =>
      _limitsOrNull?.sessionSizeFree ?? LimitsConfig.canonSessionSize;

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isDowngraded => tier == SubscriptionTier.downgraded;
  bool get isFree => tier == SubscriptionTier.free;

  /// Quiz tab blocked for free and downgraded (PRO lock).
  bool get quizBlocked => !isPremium;

  /// AI features disabled when downgraded.
  bool get aiDisabled => isDowngraded;

  /// AI quota lock when a free user has exhausted monthly requests.
  bool aiQuotaExhausted({required int requestsUsed, int? limit}) =>
      isFree && requestsUsed >= (limit ?? _aiQuota);

  /// Max writable/active buckets: app_config free, unlimited premium, first 3 downgraded.
  int get maxActiveBuckets {
    switch (tier) {
      case SubscriptionTier.premium:
        return 999;
      case SubscriptionTier.downgraded:
        return 3;
      case SubscriptionTier.free:
        return _buckets;
    }
  }

  /// Cards per generated stack: session_size_free / 12 premium [D-ENG-3].
  int get cardsPerStack => isPremium ? 12 : _sessionSize;

  /// Bucket index is read-only when downgraded and index >= 3.
  bool isBucketReadOnly(int bucketIndex) => isDowngraded && bucketIndex >= 3;

  /// Show the PRO lock on the add-bucket FAB: free at config cap, downgraded at 3.
  bool showBucketFabLock({required int currentBucketCount}) {
    if (isFree) return currentBucketCount >= _buckets;
    if (isDowngraded) return currentBucketCount >= 3;
    return false;
  }

  /// Node AI overview: app_config free, unlimited premium, blocked downgraded.
  bool get aiOverviewBlocked => isDowngraded;

  bool aiOverviewQuotaExhausted({required int overviewsUsed, int? limit}) =>
      isFree && overviewsUsed >= (limit ?? _aiOverviews);
}
