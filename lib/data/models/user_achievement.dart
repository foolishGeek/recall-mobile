// Recall · UserAchievement model — `user_achievements` row (unlock record).
// Server-authoritative: written by the 00003 triggers, read-only on the client.

import 'json_utils.dart';

class UserAchievement {
  final String userId;
  final String achievementId;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.userId,
    required this.achievementId,
    this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        userId: asString(json['user_id']),
        achievementId: asString(json['achievement_id']),
        unlockedAt: asDateTime(json['unlocked_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': dateToJson(unlockedAt),
      };

  UserAchievement copyWith({
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
