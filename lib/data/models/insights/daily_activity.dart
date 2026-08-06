// Recall · DailyActivity model — `daily_activity` row (review_count per day).
// Server-authoritative: written by the 00003 reviews trigger, read-only client.

import 'json_utils.dart';

class DailyActivity {
  final String userId;
  final DateTime activityDate;
  final int reviewCount;

  const DailyActivity({
    required this.userId,
    required this.activityDate,
    this.reviewCount = 0,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
        userId: asString(json['user_id']),
        activityDate: asDate(json['activity_date']) ?? DateTime.utc(1970),
        reviewCount: asInt(json['review_count']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'activity_date': dateToJson(activityDate),
        'review_count': reviewCount,
      };

  DailyActivity copyWith({
    String? userId,
    DateTime? activityDate,
    int? reviewCount,
  }) {
    return DailyActivity(
      userId: userId ?? this.userId,
      activityDate: activityDate ?? this.activityDate,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
