// Recall · QuizQuestionAttempt model — `quiz_question_attempts` row. The stored
// `question_json` superset [D-QUIZ-1] parses into a typed QuizQuestion.

import 'enums.dart';
import 'json_utils.dart';
import 'quiz_question.dart';

class QuizQuestionAttempt {
  final String id;
  final String attemptId;
  final String? nodeId;
  final String? bucketId;
  final QuizQuestion question;
  final String? userAnswer;
  final ReviewGrade? grade;
  final bool? isCorrect;
  final String? aiFeedback;
  final int? responseMs;
  final bool timedOut;
  final int position;
  final DateTime? answeredAt;
  final int? comfortBefore;
  final int? comfortAfter;
  final DateTime? createdAt;

  const QuizQuestionAttempt({
    required this.id,
    required this.attemptId,
    required this.question,
    this.nodeId,
    this.bucketId,
    this.userAnswer,
    this.grade,
    this.isCorrect,
    this.aiFeedback,
    this.responseMs,
    this.timedOut = false,
    this.position = 0,
    this.answeredAt,
    this.comfortBefore,
    this.comfortAfter,
    this.createdAt,
  });

  factory QuizQuestionAttempt.fromJson(Map<String, dynamic> json) =>
      QuizQuestionAttempt(
        id: asString(json['id']),
        attemptId: asString(json['attempt_id']),
        nodeId: asStringOrNull(json['node_id']),
        bucketId: asStringOrNull(json['bucket_id']),
        question: QuizQuestion.fromJson(asJsonMap(json['question_json'])),
        userAnswer: asStringOrNull(json['user_answer']),
        grade:
            json['grade'] == null ? null : ReviewGrade.fromWire(json['grade']),
        isCorrect: json['is_correct'] == null ? null : asBool(json['is_correct']),
        aiFeedback: asStringOrNull(json['ai_feedback']),
        responseMs: asIntOrNull(json['response_ms']),
        timedOut: asBool(json['timed_out']),
        position: asInt(json['position']),
        answeredAt: asDateTime(json['answered_at']),
        comfortBefore: asIntOrNull(json['comfort_before']),
        comfortAfter: asIntOrNull(json['comfort_after']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'attempt_id': attemptId,
        'node_id': nodeId,
        'bucket_id': bucketId,
        'question_json': question.toJson(),
        'user_answer': userAnswer,
        'grade': grade?.wire,
        'is_correct': isCorrect,
        'ai_feedback': aiFeedback,
        'response_ms': responseMs,
        'timed_out': timedOut,
        'position': position,
        'answered_at': dateToJson(answeredAt),
        'comfort_before': comfortBefore,
        'comfort_after': comfortAfter,
        'created_at': dateToJson(createdAt),
      };

  QuizQuestionAttempt copyWith({
    String? id,
    String? attemptId,
    String? nodeId,
    String? bucketId,
    QuizQuestion? question,
    String? userAnswer,
    ReviewGrade? grade,
    bool? isCorrect,
    String? aiFeedback,
    int? responseMs,
    bool? timedOut,
    int? position,
    DateTime? answeredAt,
    int? comfortBefore,
    int? comfortAfter,
    DateTime? createdAt,
  }) {
    return QuizQuestionAttempt(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      nodeId: nodeId ?? this.nodeId,
      bucketId: bucketId ?? this.bucketId,
      question: question ?? this.question,
      userAnswer: userAnswer ?? this.userAnswer,
      grade: grade ?? this.grade,
      isCorrect: isCorrect ?? this.isCorrect,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      responseMs: responseMs ?? this.responseMs,
      timedOut: timedOut ?? this.timedOut,
      position: position ?? this.position,
      answeredAt: answeredAt ?? this.answeredAt,
      comfortBefore: comfortBefore ?? this.comfortBefore,
      comfortAfter: comfortAfter ?? this.comfortAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
