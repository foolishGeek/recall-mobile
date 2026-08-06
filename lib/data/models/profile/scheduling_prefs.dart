// Recall · SchedulingPrefs — result of get/set_scheduling_prefs_rpc (backend
// 00047). "Memory strength" (desired retention) resolved bucket > user > global.
// The UI speaks in friendly terms; this holds the raw 0..1 fractions.

import 'json_utils.dart';

class SchedulingPrefs {
  /// Global app default retention (0..1), e.g. 0.90.
  final double? appDefault;

  /// The user's own default override, if set.
  final double? userValue;

  /// The per-bucket override, if a bucket was queried and it has one.
  final double? bucketValue;

  /// Resolved value actually used for scheduling (bucket > user > app default).
  final double effective;

  const SchedulingPrefs({
    this.appDefault,
    this.userValue,
    this.bucketValue,
    this.effective = 0.90,
  });

  factory SchedulingPrefs.fromJson(Map<String, dynamic> json) => SchedulingPrefs(
        appDefault: asDoubleOrNull(json['app_default']),
        userValue: asDoubleOrNull(json['user_value']),
        bucketValue: asDoubleOrNull(json['bucket_value']),
        effective: asDouble(json['effective'], 0.90),
      );

  /// True when this scope carries an explicit override (vs. inheriting).
  bool get hasBucketOverride => bucketValue != null;
  bool get hasUserOverride => userValue != null;

  /// Effective value as a whole-number percentage (e.g. 90).
  int get effectivePct => (effective * 100).round();
}
