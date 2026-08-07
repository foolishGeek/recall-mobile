// Recall · tier gate. Pure value object — no Get.find. Free numeric caps come
// from the injected [AppLimits] snapshot. While limits_profile = "relaxed",
// suppress paywall UX and open premium feature access (except Quiz WIP).
// See recall-backend/docs/LIMITS-ROLLBACK.md.
//
// AI features (chat, overview, quiz) are governed by [AiPolicy], mirrored from
// the server's ai_feature_policy table — this class renders that decision but
// does not re-derive it. Everything else still reads [AppLimits].

import '../config/ai_policy.dart';
import '../config/app_limits.dart';
import 'feature.dart';

enum SubscriptionTier { free, premium, downgraded }

class TierGate {
  const TierGate(this.tier, this.limits, {this.policy = AiPolicy.canon});

  final SubscriptionTier tier;
  final AppLimits limits;
  final AiPolicy policy;

  bool get isRelaxed => limits.isRelaxed;
  bool get hasPremiumAccess => isPremium || isRelaxed;
  bool get suppressPaywall => isRelaxed;

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isDowngraded => tier == SubscriptionTier.downgraded;
  bool get isFree => tier == SubscriptionTier.free;

  /// Quiz stays premium-only (WIP) — never unlocked by relaxed.
  bool get quizBlocked => !access(Feature.quiz).allowed;

  bool get aiDisabled => _entitlementDenial(Feature.aiChat) != null;
  bool get aiOverviewBlocked => _entitlementDenial(Feature.aiOverview) != null;

  bool aiQuotaExhausted({required int requestsUsed, int? limit}) =>
      _quotaExhausted(Feature.aiChat, requestsUsed, limit);

  bool aiOverviewQuotaExhausted({required int overviewsUsed, int? limit}) =>
      _quotaExhausted(Feature.aiOverview, overviewsUsed, limit);

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
      case Feature.aiOverview:
        return _aiCap(feature);
      case Feature.sessionSize:
        return cardsPerStack;
      case Feature.quiz:
        return access(Feature.quiz).allowed ? 1 : 0;
      case Feature.insightsFull:
      case Feature.youLedger:
        return hasPremiumAccess ? 1 : 0;
    }
  }

  /// Single policy switch for every pro/free feature.
  Access access(Feature feature, {int used = 0}) {
    switch (feature) {
      case Feature.quiz:
      case Feature.aiChat:
      case Feature.aiOverview:
        return _aiAccess(feature, used);

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

      case Feature.sessionSize:
        return const Access.allowed();
    }
  }

  // --- AI features: rendered from AiPolicy, never re-decided here ----------

  /// The tier-level block, if any. Null means the tier is entitled, which says
  /// nothing about whether the quota is still available.
  Access? _entitlementDenial(Feature feature) {
    final p = policy.forFeature(feature);
    if (p == null) return null;

    if (p.isRefused) {
      return Access.denied(p.clientDenial, message: p.clientMessage);
    }
    // Relaxed opens a feature only when the server says so for this profile,
    // which is why allow_downgraded is read rather than `isRelaxed`.
    if (isDowngraded && !p.allowDowngraded) {
      return Access.denied(p.clientDenial, message: p.clientMessage);
    }
    if (p.requiresPremium && !isPremium) {
      return Access.denied(p.clientDenial, message: p.clientMessage);
    }
    return null;
  }

  int _aiCap(Feature feature) {
    final p = policy.forFeature(feature);
    if (p == null) return 999;
    if (isPremium || isRelaxed) return p.premiumMonthlyCap ?? 999;
    return p.freeMonthlyCap ?? 999;
  }

  bool _quotaExhausted(Feature feature, int used, int? limit) {
    final p = policy.forFeature(feature);
    if (p == null || !p.isMetered) return false;
    if (!isFree) return false;
    return used >= (limit ?? _aiCap(feature));
  }

  Access _aiAccess(Feature feature, int used) {
    final p = policy.forFeature(feature);
    if (p == null) return const Access.allowed();

    final blocked = _entitlementDenial(feature);
    if (blocked != null) return blocked;

    if (_quotaExhausted(feature, used, null)) {
      return Access.denied(AccessDenial.quota, message: p.clientQuotaMessage);
    }
    return const Access.allowed();
  }
}
