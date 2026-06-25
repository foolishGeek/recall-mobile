// Recall · QuizQuestion — typed view of quiz_question_attempts.question_json.
// Canonical superset [D-QUIZ-1]; the client play/generate payload omits
// correct_index / reference_answer / grading_rubric (and flashcard_back until
// reveal), so those are nullable here.

import 'enums.dart';
import 'json_utils.dart';

class QuizQuestion {
  final int position;
  final QuizQuestionType type;
  final String prompt;
  final int? difficulty;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;
  final String? referenceAnswer;
  final String? gradingRubric;
  final String? flashcardBack;
  final List<String> sourceNodeIds;
  final String? nodeId;
  final String? bucketId;
  final String? bucketName;

  const QuizQuestion({
    this.position = 0,
    this.type = QuizQuestionType.mcq,
    this.prompt = '',
    this.difficulty,
    this.options = const [],
    this.correctIndex,
    this.explanation,
    this.referenceAnswer,
    this.gradingRubric,
    this.flashcardBack,
    this.sourceNodeIds = const [],
    this.nodeId,
    this.bucketId,
    this.bucketName,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        position: asInt(json['position']),
        type: QuizQuestionType.fromWire(json['type']),
        prompt: asString(json['prompt']),
        difficulty: asIntOrNull(json['difficulty']),
        options: asStringList(json['options']),
        correctIndex: asIntOrNull(json['correct_index']),
        explanation: asStringOrNull(json['explanation']),
        referenceAnswer: asStringOrNull(json['reference_answer']),
        gradingRubric: asStringOrNull(json['grading_rubric']),
        flashcardBack: asStringOrNull(json['flashcard_back']),
        sourceNodeIds: asStringList(json['source_node_ids']),
        nodeId: asStringOrNull(json['node_id']),
        bucketId: asStringOrNull(json['bucket_id']),
        bucketName: asStringOrNull(json['bucket_name']),
      );

  Map<String, dynamic> toJson() => {
        'position': position,
        'type': type.wire,
        'prompt': prompt,
        'difficulty': difficulty,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
        'reference_answer': referenceAnswer,
        'grading_rubric': gradingRubric,
        'flashcard_back': flashcardBack,
        'source_node_ids': sourceNodeIds,
        'node_id': nodeId,
        'bucket_id': bucketId,
        'bucket_name': bucketName,
      };

  QuizQuestion copyWith({
    int? position,
    QuizQuestionType? type,
    String? prompt,
    int? difficulty,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    String? referenceAnswer,
    String? gradingRubric,
    String? flashcardBack,
    List<String>? sourceNodeIds,
    String? nodeId,
    String? bucketId,
    String? bucketName,
  }) {
    return QuizQuestion(
      position: position ?? this.position,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      difficulty: difficulty ?? this.difficulty,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      referenceAnswer: referenceAnswer ?? this.referenceAnswer,
      gradingRubric: gradingRubric ?? this.gradingRubric,
      flashcardBack: flashcardBack ?? this.flashcardBack,
      sourceNodeIds: sourceNodeIds ?? this.sourceNodeIds,
      nodeId: nodeId ?? this.nodeId,
      bucketId: bucketId ?? this.bucketId,
      bucketName: bucketName ?? this.bucketName,
    );
  }
}
