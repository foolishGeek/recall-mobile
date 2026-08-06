// Recall · Review model — `reviews` row. Append-only log [D-OFF-1] with an
// idempotency key; stores before/after S/D/comfort/R and due_before/due_after
// [D-SCHEMA-4] for adherence + deterministic replay.

import 'enums.dart';
import 'json_utils.dart';

class Review {
  final String id;
  final String userId;
  final String nodeId;
  final String? stackId;
  final String? quizAttemptId;
  final ReviewSource source;
  final String idempotencyKey;
  final ReviewGrade grade;
  final double? stabilityBefore;
  final double? stabilityAfter;
  final int? difficultyBefore;
  final int? difficultyAfter;
  final int? comfortBefore;
  final int? comfortAfter;
  final double? retrievabilityBefore;
  final double? retrievabilityAfter;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final int? responseMs;
  final DateTime? reviewedAt;
  final DateTime? clientTimestamp;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.nodeId,
    required this.idempotencyKey,
    required this.grade,
    this.stackId,
    this.quizAttemptId,
    this.source = ReviewSource.stack,
    this.stabilityBefore,
    this.stabilityAfter,
    this.difficultyBefore,
    this.difficultyAfter,
    this.comfortBefore,
    this.comfortAfter,
    this.retrievabilityBefore,
    this.retrievabilityAfter,
    this.dueBefore,
    this.dueAfter,
    this.responseMs,
    this.reviewedAt,
    this.clientTimestamp,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        nodeId: asString(json['node_id']),
        stackId: asStringOrNull(json['stack_id']),
        quizAttemptId: asStringOrNull(json['quiz_attempt_id']),
        source: ReviewSource.fromWire(json['source']),
        idempotencyKey: asString(json['idempotency_key']),
        grade: ReviewGrade.fromWire(json['grade']),
        stabilityBefore: asDoubleOrNull(json['stability_before']),
        stabilityAfter: asDoubleOrNull(json['stability_after']),
        difficultyBefore: asIntOrNull(json['difficulty_before']),
        difficultyAfter: asIntOrNull(json['difficulty_after']),
        comfortBefore: asIntOrNull(json['comfort_before']),
        comfortAfter: asIntOrNull(json['comfort_after']),
        retrievabilityBefore: asDoubleOrNull(json['retrievability_before']),
        retrievabilityAfter: asDoubleOrNull(json['retrievability_after']),
        dueBefore: asDateTime(json['due_before']),
        dueAfter: asDateTime(json['due_after']),
        responseMs: asIntOrNull(json['response_ms']),
        reviewedAt: asDateTime(json['reviewed_at']),
        clientTimestamp: asDateTime(json['client_timestamp']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'node_id': nodeId,
        'stack_id': stackId,
        'quiz_attempt_id': quizAttemptId,
        'source': source.wire,
        'idempotency_key': idempotencyKey,
        'grade': grade.wire,
        'stability_before': stabilityBefore,
        'stability_after': stabilityAfter,
        'difficulty_before': difficultyBefore,
        'difficulty_after': difficultyAfter,
        'comfort_before': comfortBefore,
        'comfort_after': comfortAfter,
        'retrievability_before': retrievabilityBefore,
        'retrievability_after': retrievabilityAfter,
        'due_before': dateToJson(dueBefore),
        'due_after': dateToJson(dueAfter),
        'response_ms': responseMs,
        'reviewed_at': dateToJson(reviewedAt),
        'client_timestamp': dateToJson(clientTimestamp),
        'created_at': dateToJson(createdAt),
      };

  Review copyWith({
    String? id,
    String? userId,
    String? nodeId,
    String? stackId,
    String? quizAttemptId,
    ReviewSource? source,
    String? idempotencyKey,
    ReviewGrade? grade,
    double? stabilityBefore,
    double? stabilityAfter,
    int? difficultyBefore,
    int? difficultyAfter,
    int? comfortBefore,
    int? comfortAfter,
    double? retrievabilityBefore,
    double? retrievabilityAfter,
    DateTime? dueBefore,
    DateTime? dueAfter,
    int? responseMs,
    DateTime? reviewedAt,
    DateTime? clientTimestamp,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nodeId: nodeId ?? this.nodeId,
      stackId: stackId ?? this.stackId,
      quizAttemptId: quizAttemptId ?? this.quizAttemptId,
      source: source ?? this.source,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      grade: grade ?? this.grade,
      stabilityBefore: stabilityBefore ?? this.stabilityBefore,
      stabilityAfter: stabilityAfter ?? this.stabilityAfter,
      difficultyBefore: difficultyBefore ?? this.difficultyBefore,
      difficultyAfter: difficultyAfter ?? this.difficultyAfter,
      comfortBefore: comfortBefore ?? this.comfortBefore,
      comfortAfter: comfortAfter ?? this.comfortAfter,
      retrievabilityBefore: retrievabilityBefore ?? this.retrievabilityBefore,
      retrievabilityAfter: retrievabilityAfter ?? this.retrievabilityAfter,
      dueBefore: dueBefore ?? this.dueBefore,
      dueAfter: dueAfter ?? this.dueAfter,
      responseMs: responseMs ?? this.responseMs,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
