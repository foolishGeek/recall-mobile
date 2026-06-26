// Recall · RelearnSkill — one ranked weak node from `v_relearn_skills` [D-AI-9].
// Drives the soft "Re-learn weak skills" nudge. Read-only on the client.

import 'json_utils.dart';

class RelearnSkill {
  final String nodeId;
  final String title;
  final String bucketId;
  final String bucketName;
  final int? comfort;
  final int? difficulty;
  final int lapses;
  final int recentWeakGrades;
  final double weaknessScore;

  const RelearnSkill({
    required this.nodeId,
    this.title = '',
    this.bucketId = '',
    this.bucketName = '',
    this.comfort,
    this.difficulty,
    this.lapses = 0,
    this.recentWeakGrades = 0,
    this.weaknessScore = 0,
  });

  factory RelearnSkill.fromJson(Map<String, dynamic> json) => RelearnSkill(
        nodeId: asString(json['node_id']),
        title: asString(json['title']),
        bucketId: asString(json['bucket_id']),
        bucketName: asString(json['bucket_name']),
        comfort: asIntOrNull(json['comfort']),
        difficulty: asIntOrNull(json['difficulty']),
        lapses: asInt(json['lapses']),
        recentWeakGrades: asInt(json['recent_weak_grades']),
        weaknessScore: asDouble(json['weakness_score']),
      );
}
