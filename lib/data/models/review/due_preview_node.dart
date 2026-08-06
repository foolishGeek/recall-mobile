import 'json_utils.dart';

class DuePreviewNode {
  final String nodeId;
  final String title;
  final String bucketId;
  final String bucketName;
  final int priority;
  final int difficulty;
  final DateTime? dueAt;
  final double heat;

  const DuePreviewNode({
    required this.nodeId,
    required this.title,
    required this.bucketId,
    required this.bucketName,
    required this.priority,
    required this.difficulty,
    this.dueAt,
    required this.heat,
  });

  factory DuePreviewNode.fromJson(Map<String, dynamic> json) => DuePreviewNode(
        nodeId: asString(json['node_id']),
        title: asString(json['title']),
        bucketId: asString(json['bucket_id']),
        bucketName: asString(json['bucket_name']),
        priority: asInt(json['priority'], 3),
        difficulty: asInt(json['difficulty'], 3),
        dueAt: asDateTime(json['due_at']),
        heat: asDouble(json['heat']),
      );
}
