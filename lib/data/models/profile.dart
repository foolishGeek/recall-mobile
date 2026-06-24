// Recall · Profile model — `profiles` row. Gamification + AI/billing columns are
// server-authoritative (written by migration 00003 triggers / ai-forge); the
// client only edits preference fields (see ProfileRepository.updatePreferences).

import 'json_utils.dart';

class Profile {
  final String id;
  // Preferences (client-editable).
  final String timezone;
  final String locale;
  final String theme;
  final bool onboardingDone;
  final bool pushOptIn;
  final String dropFrequency;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String defaultCoolingPeriod; // raw Postgres interval text
  final String? displayName;
  final bool hapticsOnDrop;
  final bool analyticsOptIn;
  final int? sessionSizeOverride;
  // Gamification (server-authoritative, read-only on client).
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakActivityDate;
  final double? retentionWithRecall;
  final double? retentionBaseline;
  final int memoriesSaved;
  // Entitlement / AI counters (server-authoritative, read-only on client).
  final bool hadPremium;
  final int aiCreditBalance;
  final DateTime? aiCooldownUntil;
  final String? aiUsagePeriod;
  final int aiRequestsMonth;
  final int aiOverviewsMonth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.timezone = 'UTC',
    this.locale = 'en',
    this.theme = 'system',
    this.onboardingDone = false,
    this.pushOptIn = false,
    this.dropFrequency = 'daily',
    this.quietHoursStart,
    this.quietHoursEnd,
    this.defaultCoolingPeriod = '24:00:00',
    this.displayName,
    this.hapticsOnDrop = true,
    this.analyticsOptIn = true,
    this.sessionSizeOverride,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakActivityDate,
    this.retentionWithRecall,
    this.retentionBaseline,
    this.memoriesSaved = 0,
    this.hadPremium = false,
    this.aiCreditBalance = 0,
    this.aiCooldownUntil,
    this.aiUsagePeriod,
    this.aiRequestsMonth = 0,
    this.aiOverviewsMonth = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Best-effort default cooling period as a [Duration] (raw text kept above).
  Duration? get defaultCoolingPeriodDuration =>
      parseInterval(defaultCoolingPeriod);

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: asString(json['id']),
        timezone: asString(json['timezone'], 'UTC'),
        locale: asString(json['locale'], 'en'),
        theme: asString(json['theme'], 'system'),
        onboardingDone: asBool(json['onboarding_done']),
        pushOptIn: asBool(json['push_opt_in']),
        dropFrequency: asString(json['drop_frequency'], 'daily'),
        quietHoursStart: asStringOrNull(json['quiet_hours_start']),
        quietHoursEnd: asStringOrNull(json['quiet_hours_end']),
        defaultCoolingPeriod:
            asString(json['default_cooling_period'], '24:00:00'),
        displayName: asStringOrNull(json['display_name']),
        hapticsOnDrop: asBool(json['haptics_on_drop'], true),
        analyticsOptIn: asBool(json['analytics_opt_in'], true),
        sessionSizeOverride: asIntOrNull(json['session_size_override']),
        xp: asInt(json['xp']),
        level: asInt(json['level'], 1),
        currentStreak: asInt(json['current_streak']),
        longestStreak: asInt(json['longest_streak']),
        lastStreakActivityDate: asDate(json['last_streak_activity_date']),
        retentionWithRecall: asDoubleOrNull(json['retention_with_recall']),
        retentionBaseline: asDoubleOrNull(json['retention_baseline']),
        memoriesSaved: asInt(json['memories_saved']),
        hadPremium: asBool(json['had_premium']),
        aiCreditBalance: asInt(json['ai_credit_balance']),
        aiCooldownUntil: asDateTime(json['ai_cooldown_until']),
        aiUsagePeriod: asStringOrNull(json['ai_usage_period']),
        aiRequestsMonth: asInt(json['ai_requests_month']),
        aiOverviewsMonth: asInt(json['ai_overviews_month']),
        createdAt: asDateTime(json['created_at']),
        updatedAt: asDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timezone': timezone,
        'locale': locale,
        'theme': theme,
        'onboarding_done': onboardingDone,
        'push_opt_in': pushOptIn,
        'drop_frequency': dropFrequency,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'default_cooling_period': defaultCoolingPeriod,
        'display_name': displayName,
        'haptics_on_drop': hapticsOnDrop,
        'analytics_opt_in': analyticsOptIn,
        'session_size_override': sessionSizeOverride,
        'xp': xp,
        'level': level,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_streak_activity_date': dateToJson(lastStreakActivityDate),
        'retention_with_recall': retentionWithRecall,
        'retention_baseline': retentionBaseline,
        'memories_saved': memoriesSaved,
        'had_premium': hadPremium,
        'ai_credit_balance': aiCreditBalance,
        'ai_cooldown_until': dateToJson(aiCooldownUntil),
        'ai_usage_period': aiUsagePeriod,
        'ai_requests_month': aiRequestsMonth,
        'ai_overviews_month': aiOverviewsMonth,
        'created_at': dateToJson(createdAt),
        'updated_at': dateToJson(updatedAt),
      };

  Profile copyWith({
    String? id,
    String? timezone,
    String? locale,
    String? theme,
    bool? onboardingDone,
    bool? pushOptIn,
    String? dropFrequency,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? defaultCoolingPeriod,
    String? displayName,
    bool? hapticsOnDrop,
    bool? analyticsOptIn,
    int? sessionSizeOverride,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStreakActivityDate,
    double? retentionWithRecall,
    double? retentionBaseline,
    int? memoriesSaved,
    bool? hadPremium,
    int? aiCreditBalance,
    DateTime? aiCooldownUntil,
    String? aiUsagePeriod,
    int? aiRequestsMonth,
    int? aiOverviewsMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      theme: theme ?? this.theme,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      pushOptIn: pushOptIn ?? this.pushOptIn,
      dropFrequency: dropFrequency ?? this.dropFrequency,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      defaultCoolingPeriod: defaultCoolingPeriod ?? this.defaultCoolingPeriod,
      displayName: displayName ?? this.displayName,
      hapticsOnDrop: hapticsOnDrop ?? this.hapticsOnDrop,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
      sessionSizeOverride: sessionSizeOverride ?? this.sessionSizeOverride,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakActivityDate:
          lastStreakActivityDate ?? this.lastStreakActivityDate,
      retentionWithRecall: retentionWithRecall ?? this.retentionWithRecall,
      retentionBaseline: retentionBaseline ?? this.retentionBaseline,
      memoriesSaved: memoriesSaved ?? this.memoriesSaved,
      hadPremium: hadPremium ?? this.hadPremium,
      aiCreditBalance: aiCreditBalance ?? this.aiCreditBalance,
      aiCooldownUntil: aiCooldownUntil ?? this.aiCooldownUntil,
      aiUsagePeriod: aiUsagePeriod ?? this.aiUsagePeriod,
      aiRequestsMonth: aiRequestsMonth ?? this.aiRequestsMonth,
      aiOverviewsMonth: aiOverviewsMonth ?? this.aiOverviewsMonth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
