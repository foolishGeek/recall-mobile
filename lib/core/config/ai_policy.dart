// AI entitlement policy mirrored from `v_ai_policy` (migration 00060). The
// server decides; this snapshot only lets the UI show the right lock and copy
// without a round trip. [AiPolicy.canon] mirrors the migration seeds and is the
// cold-start default until the first successful fetch — so TierGate has one
// code path, and the fallback is data rather than a second set of rules.

import 'package:flutter/foundation.dart';

import '../gates/feature.dart';

@immutable
class AiFeaturePolicy {
  const AiFeaturePolicy({
    required this.enabled,
    required this.access,
    this.counterPool,
    this.freeMonthlyCap,
    this.premiumMonthlyCap,
    this.minTier = 'free',
    this.allowDowngraded = false,
    this.clientDenial = AccessDenial.paywall,
    this.clientMessage,
    this.clientQuotaMessage,
  });

  factory AiFeaturePolicy.fromRow(Map<String, dynamic> row) {
    return AiFeaturePolicy(
      enabled: row['enabled'] as bool? ?? true,
      access: row['access']?.toString() ?? 'metered',
      counterPool: row['counter_pool']?.toString(),
      freeMonthlyCap: _asInt(row['free_monthly_cap']),
      premiumMonthlyCap: _asInt(row['premium_monthly_cap']),
      minTier: row['min_tier']?.toString() ?? 'free',
      allowDowngraded: row['allow_downgraded'] as bool? ?? false,
      clientDenial: _denialFrom(row['client_denial']?.toString()),
      clientMessage: row['client_message']?.toString(),
      clientQuotaMessage: row['client_quota_message']?.toString(),
    );
  }

  final bool enabled;

  /// free · metered · premium_only · credits_only · internal · disabled.
  final String access;
  final String? counterPool;

  /// null means unlimited.
  final int? freeMonthlyCap;
  final int? premiumMonthlyCap;
  final String minTier;
  final bool allowDowngraded;

  /// How the app presents a block, so "upsell" vs "coming soon" is server-set.
  final AccessDenial clientDenial;
  final String? clientMessage;
  final String? clientQuotaMessage;

  bool get isMetered => access == 'metered';
  bool get requiresPremium => minTier == 'premium';
  bool get isRefused => !enabled || access == 'disabled';

  static AccessDenial _denialFrom(String? v) {
    switch (v) {
      case 'wip':
        return AccessDenial.wip;
      case 'quota':
        return AccessDenial.quota;
      default:
        return AccessDenial.paywall;
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

@immutable
class AiPolicy {
  const AiPolicy(this.byFeature);

  final Map<String, AiFeaturePolicy> byFeature;

  AiFeaturePolicy? forFeature(Feature feature) {
    final key = feature.policyKey;
    return key == null ? null : byFeature[key];
  }

  /// Mirrors the `canon` seeds in migration 00060. Used before the first fetch
  /// and whenever a refresh fails, so gate UX never depends on the network.
  static const AiPolicy canon = AiPolicy({
    'rag_chat': AiFeaturePolicy(
      enabled: true,
      access: 'metered',
      counterPool: 'requests',
      freeMonthlyCap: 50,
      clientMessage: 'AI unavailable — resubscribe to continue',
      clientQuotaMessage: 'Monthly AI limit reached',
    ),
    'evaluate': AiFeaturePolicy(
      enabled: true,
      access: 'metered',
      counterPool: 'overviews',
      freeMonthlyCap: 2,
      clientQuotaMessage: 'Monthly overview limit reached',
    ),
    'quiz_generate': AiFeaturePolicy(
      enabled: true,
      access: 'metered',
      counterPool: 'requests',
      freeMonthlyCap: 50,
      minTier: 'premium',
      clientDenial: AccessDenial.wip,
      clientMessage: 'Quiz is in progress for Premium.',
      clientQuotaMessage: 'Monthly AI limit reached',
    ),
  });
}
