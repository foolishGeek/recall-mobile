// Immutable free-tier numeric snapshot. LimitsConfig holds one reactive copy;
// TierGate receives it by value so Obx rebuilds when the snapshot is replaced.

class AppLimits {
  const AppLimits({
    required this.profile,
    required this.stacksFreeMonthly,
    required this.bucketsFreeWritable,
    required this.aiQuotaFreeMonthly,
    required this.aiOverviewFreeMonthly,
    required this.sessionSizeFree,
  });

  static const String profileCanon = 'canon';
  static const String profileRelaxed = 'relaxed';

  static const int canonStacks = 2;
  static const int canonBuckets = 2;
  static const int canonAiQuota = 50;
  static const int canonAiOverviews = 2;
  static const int canonSessionSize = 8;

  static const int relaxedStacks = 999;
  static const int relaxedBuckets = 999;
  static const int relaxedAiQuota = 500;
  static const int relaxedAiOverviews = 50;
  static const int relaxedSessionSize = 12;

  final String profile;
  final int stacksFreeMonthly;
  final int bucketsFreeWritable;
  final int aiQuotaFreeMonthly;
  final int aiOverviewFreeMonthly;
  final int sessionSizeFree;

  bool get isRelaxed => profile == profileRelaxed;

  /// Hide discrete stack meters when the free cap is effectively uncapped.
  bool get showStacksMeter => stacksFreeMonthly <= 12;

  static const AppLimits canon = AppLimits(
    profile: profileCanon,
    stacksFreeMonthly: canonStacks,
    bucketsFreeWritable: canonBuckets,
    aiQuotaFreeMonthly: canonAiQuota,
    aiOverviewFreeMonthly: canonAiOverviews,
    sessionSizeFree: canonSessionSize,
  );

  static const AppLimits relaxed = AppLimits(
    profile: profileRelaxed,
    stacksFreeMonthly: relaxedStacks,
    bucketsFreeWritable: relaxedBuckets,
    aiQuotaFreeMonthly: relaxedAiQuota,
    aiOverviewFreeMonthly: relaxedAiOverviews,
    sessionSizeFree: relaxedSessionSize,
  );

  AppLimits copyWith({
    String? profile,
    int? stacksFreeMonthly,
    int? bucketsFreeWritable,
    int? aiQuotaFreeMonthly,
    int? aiOverviewFreeMonthly,
    int? sessionSizeFree,
  }) {
    return AppLimits(
      profile: profile ?? this.profile,
      stacksFreeMonthly: stacksFreeMonthly ?? this.stacksFreeMonthly,
      bucketsFreeWritable: bucketsFreeWritable ?? this.bucketsFreeWritable,
      aiQuotaFreeMonthly: aiQuotaFreeMonthly ?? this.aiQuotaFreeMonthly,
      aiOverviewFreeMonthly:
          aiOverviewFreeMonthly ?? this.aiOverviewFreeMonthly,
      sessionSizeFree: sessionSizeFree ?? this.sessionSizeFree,
    );
  }
}
