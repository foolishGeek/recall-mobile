// Recall · QuizConfig model — `quiz_configs` row (a saved quiz setup).

import 'enums.dart';
import 'json_utils.dart';

class QuizConfig {
  final String id;
  final String userId;
  final QuizMode mode;
  final List<String> bucketIds;
  final List<String> nodeIds;
  final String? prompt;
  final bool useMyNotes;
  final int questionCount;
  final QuizQuestionType questionType;
  final int difficulty;
  final int? timerSec;
  final DateTime? createdAt;

  const QuizConfig({
    required this.id,
    required this.userId,
    this.mode = QuizMode.freehand,
    this.bucketIds = const [],
    this.nodeIds = const [],
    this.prompt,
    this.useMyNotes = true,
    this.questionCount = 10,
    this.questionType = QuizQuestionType.mcq,
    this.difficulty = 3,
    this.timerSec,
    this.createdAt,
  });

  factory QuizConfig.fromJson(Map<String, dynamic> json) => QuizConfig(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        mode: QuizMode.fromWire(json['mode']),
        bucketIds: asStringList(json['bucket_ids']),
        nodeIds: asStringList(json['node_ids']),
        prompt: asStringOrNull(json['prompt']),
        useMyNotes: asBool(json['use_my_notes'], true),
        questionCount: asInt(json['question_count'], 10),
        questionType: QuizQuestionType.fromWire(json['question_type']),
        difficulty: asInt(json['difficulty'], 3),
        timerSec: asIntOrNull(json['timer_sec']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mode': mode.wire,
        'bucket_ids': bucketIds,
        'node_ids': nodeIds,
        'prompt': prompt,
        'use_my_notes': useMyNotes,
        'question_count': questionCount,
        'question_type': questionType.wire,
        'difficulty': difficulty,
        'timer_sec': timerSec,
        'created_at': dateToJson(createdAt),
      };

  QuizConfig copyWith({
    String? id,
    String? userId,
    QuizMode? mode,
    List<String>? bucketIds,
    List<String>? nodeIds,
    String? prompt,
    bool? useMyNotes,
    int? questionCount,
    QuizQuestionType? questionType,
    int? difficulty,
    int? timerSec,
    DateTime? createdAt,
  }) {
    return QuizConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      bucketIds: bucketIds ?? this.bucketIds,
      nodeIds: nodeIds ?? this.nodeIds,
      prompt: prompt ?? this.prompt,
      useMyNotes: useMyNotes ?? this.useMyNotes,
      questionCount: questionCount ?? this.questionCount,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      timerSec: timerSec ?? this.timerSec,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
