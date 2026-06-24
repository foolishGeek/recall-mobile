// Recall · AiEvaluation model — `node_ai_evaluations` row (AI overview cached by
// content_hash). Written server-side by ai-forge (S06); read-only on the client.

import 'json_utils.dart';

class AiEvaluation {
  final String id;
  final String nodeId;
  final int? qualityScore;
  final int? suggestedComfort;
  final int? suggestedDifficulty;
  final String? feedback;
  final String? model;
  final String? contentHash;
  final DateTime? createdAt;

  const AiEvaluation({
    required this.id,
    required this.nodeId,
    this.qualityScore,
    this.suggestedComfort,
    this.suggestedDifficulty,
    this.feedback,
    this.model,
    this.contentHash,
    this.createdAt,
  });

  factory AiEvaluation.fromJson(Map<String, dynamic> json) => AiEvaluation(
        id: asString(json['id']),
        nodeId: asString(json['node_id']),
        qualityScore: asIntOrNull(json['quality_score']),
        suggestedComfort: asIntOrNull(json['suggested_comfort']),
        suggestedDifficulty: asIntOrNull(json['suggested_difficulty']),
        feedback: asStringOrNull(json['feedback']),
        model: asStringOrNull(json['model']),
        contentHash: asStringOrNull(json['content_hash']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'quality_score': qualityScore,
        'suggested_comfort': suggestedComfort,
        'suggested_difficulty': suggestedDifficulty,
        'feedback': feedback,
        'model': model,
        'content_hash': contentHash,
        'created_at': dateToJson(createdAt),
      };

  AiEvaluation copyWith({
    String? id,
    String? nodeId,
    int? qualityScore,
    int? suggestedComfort,
    int? suggestedDifficulty,
    String? feedback,
    String? model,
    String? contentHash,
    DateTime? createdAt,
  }) {
    return AiEvaluation(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      qualityScore: qualityScore ?? this.qualityScore,
      suggestedComfort: suggestedComfort ?? this.suggestedComfort,
      suggestedDifficulty: suggestedDifficulty ?? this.suggestedDifficulty,
      feedback: feedback ?? this.feedback,
      model: model ?? this.model,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
