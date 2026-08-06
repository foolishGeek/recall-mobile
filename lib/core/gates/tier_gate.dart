// Recall · tier gate. Pure value object — no Get.find. Free numeric caps come
// from the injected [AppLimits] snapshot. While limits_profile = "relaxed",
// suppress paywall UX and open premium feature access (except Quiz WIP).
// See recall-backend/docs/LIMITS-ROLLBACK.md.

import '../config/app_limits.dart';
import 'feature.dart';

enum SubscriptionTier { free, premium, downgraded }

class TierGate {
  const TierGate(this.tier, this.limits);

  final SubscriptionTier tier;
  final AppLimits limits;

  bool get isRelaxed => limits.isRelaxed;
  bool get hasPremiumAccess => isPremium || isRelaxed;
  bool get suppressPaywall => isRelaxed;

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isDowngraded => tier == SubscriptionTier.downgraded;
  bool get isFree => tier == SubscriptionTier.free;

  /// Quiz stays premium-only (WIP) — never unlocked by relaxed.
  bool get quizBlocked => !isPremium;

  bool get aiDisabled => isDowngraded && !isRelaxed;
  bool get aiOverviewBlocked => isDowngraded && !isRelaxed;

  bool aiQuotaExhausted({required int requestsUsed, int? limit}) =>
      isFree && requestsUsed >= (limit ?? limits.aiQuotaFreeMonthly);

  bool aiOverviewQuotaExhausted({required int overviewsUsed, int? limit}) =>
      isFree && overviewsUsed >= (limit ?? limits.aiOverviewFreeMonthly);

  int get cardsPerStack => hasPremiumAccess ? 12 : limits.sessionSizeFree;

  /// Show the PRO lock on the add-bucket FAB.
  bool showBucketFabLock({required int currentBucketCount}) {
    if (isRelaxed) return false;
    if (isFree) return currentBucketCount >= limits.bucketsFreeWritable;
    if (isDowngraded) return currentBucketCount >= 3;
    return false;
  }

  /// Numeric cap for a feature (stacks/month, buckets, AI quotas, session size).
  int capFor(Feature feature) {
    switch (feature) {
      case Feature.reviewStack:
        return hasPremiumAccess ? 999 : limits.stacksFreeMonthly;
      case Feature.bucketCreate:
        if (isRelaxed || isPremium) return 999;
        if (isDowngraded) return 3;
        return limits.bucketsFreeWritable;
      case Feature.aiChat:
        return hasPremiumAccess ? 999 : limits.aiQuotaFreeMonthly;
      case Feature.aiOverview:
        return hasPremiumAccess ? 999 : limits.aiOverviewFreeMonthly;
      case Feature.sessionSize:
        return cardsPerStack;
      case Feature.insightsFull:
      case Feature.youLedger:
      case Feature.quiz:
        return hasPremiumAccess || (feature != Feature.quiz && isRelaxed)
            ? 1
            : 0;
    }
  }

  /// Single policy switch for every pro/free feature.
  Access access(Feature feature, {int used = 0}) {
    switch (feature) {
      case Feature.quiz:
        if (isPremium) return const Access.allowed();
        return const Access.denied(AccessDenial.wip,
            message: 'Quiz is in progress for Premium.');

      case Feature.insightsFull:
      case Feature.youLedger:
        if (hasPremiumAccess) return const Access.allowed();
        return const Access.denied(AccessDenial.paywall);

      case Feature.reviewStack:
        if (hasPremiumAccess) return const Access.allowed();
        if (used >= limits.stacksFreeMonthly) {
          return Access.denied(
            AccessDenial.paywall,
            message:
                'Free plan allows ${limits.stacksFreeMonthly} stacks per month.',
          );
        }
        return const Access.allowed();

      case Feature.bucketCreate:
        if (isRelaxed || isPremium) return const Access.allowed();
        final cap = isDowngraded ? 3 : limits.bucketsFreeWritable;
        if (used >= cap) {
          return Access.denied(
            AccessDenial.paywall,
            message: 'Free plan allows up to $cap buckets.',
          );
        }
        return const Access.allowed();

      case Feature.aiChat:
        if (aiDisabled) {
          return const Access.denied(AccessDenial.paywall,
              message: 'AI unavailable — resubscribe to continue');
        }
        if (aiQuotaExhausted(requestsUsed: used)) {
          return Access.denied(
            AccessDenial.quota,
            message: 'Monthly AI limit reached',
          );
        }
        return const Access.allowed();

      case Feature.aiOverview:
        if (aiOverviewBlocked) {
          return const Access.denied(AccessDenial.paywall);
        }
        if (aiOverviewQuotaExhausted(overviewsUsed: used)) {
          return Access.denied(
            AccessDenial.quota,
            message: 'Monthly overview limit reached',
          );
        }
        return const Access.allowed();

      case Feature.sessionSize:
        return const Access.allowed();
    }
  }
}
