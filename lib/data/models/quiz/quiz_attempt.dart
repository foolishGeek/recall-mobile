// Recall · QuizAttempt model — `quiz_attempts` row. `question_count` is
// denormalized at generate time [D-SCHEMA-5] for the Recent-quizzes chips.

import 'enums.dart';
import 'json_utils.dart';

class QuizAttempt {
  final String id;
  final String userId;
  final String? configId;
  final QuizMode mode;
  final QuizQuestionType questionType;
  final QuizAttemptStatus status;
  final double? scorePct;
  final int? questionCount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    this.configId,
    this.mode = QuizMode.freehand,
    this.questionType = QuizQuestionType.mcq,
    this.status = QuizAttemptStatus.inProgress,
    this.scorePct,
    this.questionCount,
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        configId: asStringOrNull(json['config_id']),
        mode: QuizMode.fromWire(json['mode']),
        questionType: QuizQuestionType.fromWire(json['question_type']),
        status: QuizAttemptStatus.fromWire(json['status']),
        scorePct: asDoubleOrNull(json['score_pct']),
        questionCount: asIntOrNull(json['question_count']),
        startedAt: asDateTime(json['started_at']),
        completedAt: asDateTime(json['completed_at']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'config_id': configId,
        'mode': mode.wire,
        'question_type': questionType.wire,
        'status': status.wire,
        'score_pct': scorePct,
        'question_count': questionCount,
        'started_at': dateToJson(startedAt),
        'completed_at': dateToJson(completedAt),
        'created_at': dateToJson(createdAt),
      };

  QuizAttempt copyWith({
    String? id,
    String? userId,
    String? configId,
    QuizMode? mode,
    QuizQuestionType? questionType,
    QuizAttemptStatus? status,
    double? scorePct,
    int? questionCount,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      configId: configId ?? this.configId,
      mode: mode ?? this.mode,
      questionType: questionType ?? this.questionType,
      status: status ?? this.status,
      scorePct: scorePct ?? this.scorePct,
      questionCount: questionCount ?? this.questionCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
