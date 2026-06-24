// Recall · Node model — `nodes` row. FSRS scheduling fields live here and are
// written client-side by the engine (S04). `link_preview_json` → LinkPreview.

import 'enums.dart';
import 'json_utils.dart';
import 'link_preview.dart';

class Node {
  final String id;
  final String bucketId;
  final NodeType type;
  final String title;
  final String? markdown;
  final String? url;
  final LinkPreview? linkPreview;
  final int difficulty;
  final int priority;
  final int comfort;
  final double? stability;
  final DateTime? lastReviewedAt;
  final DateTime? dueAt;
  final int reps;
  final int lapses;
  final NodeState state;
  final ReviewGrade? lastGrade;
  final int? lastResponseMs;
  final String? extractedText;
  final String? contentHash;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Node({
    required this.id,
    required this.bucketId,
    this.type = NodeType.text,
    this.title = '',
    this.markdown,
    this.url,
    this.linkPreview,
    this.difficulty = 3,
    this.priority = 3,
    this.comfort = 50,
    this.stability,
    this.lastReviewedAt,
    this.dueAt,
    this.reps = 0,
    this.lapses = 0,
    this.state = NodeState.newNode,
    this.lastGrade,
    this.lastResponseMs,
    this.extractedText,
    this.contentHash,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    final lp = json['link_preview_json'];
    return Node(
      id: asString(json['id']),
      bucketId: asString(json['bucket_id']),
      type: NodeType.fromWire(json['type']),
      title: asString(json['title']),
      markdown: asStringOrNull(json['markdown']),
      url: asStringOrNull(json['url']),
      linkPreview: lp is Map ? LinkPreview.fromJson(asJsonMap(lp)) : null,
      difficulty: asInt(json['difficulty'], 3),
      priority: asInt(json['priority'], 3),
      comfort: asInt(json['comfort'], 50),
      stability: asDoubleOrNull(json['stability']),
      lastReviewedAt: asDateTime(json['last_reviewed_at']),
      dueAt: asDateTime(json['due_at']),
      reps: asInt(json['reps']),
      lapses: asInt(json['lapses']),
      state: NodeState.fromWire(json['state']),
      lastGrade:
          json['last_grade'] == null ? null : ReviewGrade.fromWire(json['last_grade']),
      lastResponseMs: asIntOrNull(json['last_response_ms']),
      extractedText: asStringOrNull(json['extracted_text']),
      contentHash: asStringOrNull(json['content_hash']),
      deletedAt: asDateTime(json['deleted_at']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bucket_id': bucketId,
        'type': type.wire,
        'title': title,
        'markdown': markdown,
        'url': url,
        'link_preview_json': linkPreview?.toJson(),
        'difficulty': difficulty,
        'priority': priority,
        'comfort': comfort,
        'stability': stability,
        'last_reviewed_at': dateToJson(lastReviewedAt),
        'due_at': dateToJson(dueAt),
        'reps': reps,
        'lapses': lapses,
        'state': state.wire,
        'last_grade': lastGrade?.wire,
        'last_response_ms': lastResponseMs,
        'extracted_text': extractedText,
        'content_hash': contentHash,
        'deleted_at': dateToJson(deletedAt),
        'created_at': dateToJson(createdAt),
        'updated_at': dateToJson(updatedAt),
      };

  Node copyWith({
    String? id,
    String? bucketId,
    NodeType? type,
    String? title,
    String? markdown,
    String? url,
    LinkPreview? linkPreview,
    int? difficulty,
    int? priority,
    int? comfort,
    double? stability,
    DateTime? lastReviewedAt,
    DateTime? dueAt,
    int? reps,
    int? lapses,
    NodeState? state,
    ReviewGrade? lastGrade,
    int? lastResponseMs,
    String? extractedText,
    String? contentHash,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Node(
      id: id ?? this.id,
      bucketId: bucketId ?? this.bucketId,
      type: type ?? this.type,
      title: title ?? this.title,
      markdown: markdown ?? this.markdown,
      url: url ?? this.url,
      linkPreview: linkPreview ?? this.linkPreview,
      difficulty: difficulty ?? this.difficulty,
      priority: priority ?? this.priority,
      comfort: comfort ?? this.comfort,
      stability: stability ?? this.stability,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      dueAt: dueAt ?? this.dueAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
      lastGrade: lastGrade ?? this.lastGrade,
      lastResponseMs: lastResponseMs ?? this.lastResponseMs,
      extractedText: extractedText ?? this.extractedText,
      contentHash: contentHash ?? this.contentHash,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
