// Recall · notification analytics models for the Insights "Recall Drop open %"
// card. `v_notification_stats` = 30-day totals (rate numeral); `v_notification_daily`
// = per-day sent/opened (mini bars). Written server-side by S16; read-only here.

import 'json_utils.dart';

/// `v_notification_stats` row — 30-day Drop send/open totals.
class NotificationStats {
  final int sent30d;
  final int opened30d;

  const NotificationStats({this.sent30d = 0, this.opened30d = 0});

  factory NotificationStats.fromJson(Map<String, dynamic> json) =>
      NotificationStats(
        sent30d: asInt(json['sent_30d']),
        opened30d: asInt(json['opened_30d']),
      );

  /// Open rate 0..1, or null when nothing was sent (avoid divide-by-zero → "—").
  double? get openRate => sent30d == 0 ? null : (opened30d / sent30d).clamp(0.0, 1.0);
}

/// `v_notification_daily` row — one day's sent/opened counts (mini bar chart).
class NotificationDaily {
  final DateTime day;
  final int sent;
  final int opened;

  const NotificationDaily({
    required this.day,
    this.sent = 0,
    this.opened = 0,
  });

  factory NotificationDaily.fromJson(Map<String, dynamic> json) =>
      NotificationDaily(
        day: asDate(json['day']) ?? DateTime.utc(1970),
        sent: asInt(json['sent']),
        opened: asInt(json['opened']),
      );

  /// Per-day open ratio 0..1 (0 when nothing sent) — drives mini-bar height.
  double get openRatio => sent == 0 ? 0 : (opened / sent).clamp(0.0, 1.0);
}
