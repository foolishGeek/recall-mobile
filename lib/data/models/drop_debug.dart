// Recall · DropDebug — result of drop_debug_rpc (backend 00055). An honest,
// per-user breakdown of why a Recall Drop will or won't fire. Powers the calm
// "Reminders" diagnostic in Settings. Read-only; mirrors compute_due_candidates.

import 'json_utils.dart';

class DropDebug {
  final bool pushOptIn;
  final int deviceTokenCount;
  final String reminderStyle; // Gentle / Standard / Persistent

  final int activeBucketCount;
  final int coolingBucketCount;
  final bool allCooling;

  final int duePoolSize;
  final int newlyDue;
  final int threshold;
  final bool meetsThreshold;

  final bool inQuietHours;
  final int sentToday;
  final int maxPerDay;
  final bool underDailyCap;
  final bool minIntervalOk;

  final DateTime? lastSentAt;
  final DateTime? nextDropAt;
  final bool wouldDropNow;

  /// Plain-English blockers, ordered by what to fix first. Empty when a Drop is
  /// on track (or already firing).
  final List<String> reasons;

  const DropDebug({
    required this.pushOptIn,
    required this.deviceTokenCount,
    required this.reminderStyle,
    required this.activeBucketCount,
    required this.coolingBucketCount,
    required this.allCooling,
    required this.duePoolSize,
    required this.newlyDue,
    required this.threshold,
    required this.meetsThreshold,
    required this.inQuietHours,
    required this.sentToday,
    required this.maxPerDay,
    required this.underDailyCap,
    required this.minIntervalOk,
    required this.wouldDropNow,
    required this.reasons,
    this.lastSentAt,
    this.nextDropAt,
  });

  factory DropDebug.fromJson(Map<String, dynamic> json) => DropDebug(
        pushOptIn: asBool(json['push_opt_in']),
        deviceTokenCount: asInt(json['device_token_count']),
        reminderStyle: asString(json['reminder_style'], 'Standard'),
        activeBucketCount: asInt(json['active_bucket_count']),
        coolingBucketCount: asInt(json['cooling_bucket_count']),
        allCooling: asBool(json['all_cooling']),
        duePoolSize: asInt(json['due_pool_size']),
        newlyDue: asInt(json['newly_due']),
        threshold: asInt(json['threshold']),
        meetsThreshold: asBool(json['meets_threshold']),
        inQuietHours: asBool(json['in_quiet_hours']),
        sentToday: asInt(json['sent_today']),
        maxPerDay: asInt(json['max_per_day']),
        underDailyCap: asBool(json['under_daily_cap']),
        minIntervalOk: asBool(json['min_interval_ok']),
        wouldDropNow: asBool(json['would_drop_now']),
        lastSentAt: asDateTime(json['last_sent_at']),
        nextDropAt: asDateTime(json['next_drop_at']),
        reasons: asStringList(json['reasons']),
      );

  /// True when reminders can actually reach this device (the two hard gates).
  bool get canDeliver => pushOptIn && deviceTokenCount > 0;

  /// A calm one-line headline for the diagnostic.
  String get headline {
    if (!pushOptIn) return 'Reminders are off';
    if (deviceTokenCount == 0) return 'This device isn’t set up for reminders';
    if (wouldDropNow) return 'A Drop is ready to send';
    if (nextDropAt != null) return 'Reminders are on';
    return 'Reminders are on · nothing due yet';
  }
}
