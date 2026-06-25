// Recall · QuizResult — typed view of the `quiz-complete` response [D-EF-3].
// Every field maps to a server-computed value (score, breakdown, weak topics,
// comfort transitions, review-missed nodes, XP). The client only renders these.

import 'enums.dart';
import 'json_utils.dart';

class QuizResult {
  final double scorePct;
  final int total;
  final int correct;
  final int xpAwarded;
  final String? scopeLabel;
  final List<QuizResultQuestion> questions;
  final List<QuizWeakTopic> weakTopics;
  final List<QuizComfortUpdate> comfortUpdates;
  final List<String> reviewMissedNodeIds;

  const QuizResult({
    this.scorePct = 0,
    this.total = 0,
    this.correct = 0,
    this.xpAwarded = 0,
    this.scopeLabel,
    this.questions = const [],
    this.weakTopics = const [],
    this.comfortUpdates = const [],
    this.reviewMissedNodeIds = const [],
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        scorePct: asDouble(json['score_pct']),
        total: asInt(json['total']),
        correct: asInt(json['correct']),
        xpAwarded: asInt(json['xp_awarded']),
        scopeLabel: asStringOrNull(json['scope_label']),
        questions: _list(json['questions'], QuizResultQuestion.fromJson),
        weakTopics: _list(json['weak_topics'], QuizWeakTopic.fromJson),
        comfortUpdates: _list(json['comfort_updates'], QuizComfortUpdate.fromJson),
        reviewMissedNodeIds: asStringList(json['review_missed_node_ids']),
      );

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) from) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => from(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList(growable: false);
  }
}

class QuizResultQuestion {
  final String questionAttemptId;
  final String prompt;
  final bool isCorrect;
  final String? userAnswer;
  final String? correctAnswer;
  final String? aiFeedback;
  final ReviewGrade? grade;
  final String? nodeId;
  final String? nodeTitle;

  const QuizResultQuestion({
    required this.questionAttemptId,
    this.prompt = '',
    this.isCorrect = false,
    this.userAnswer,
    this.correctAnswer,
    this.aiFeedback,
    this.grade,
    this.nodeId,
    this.nodeTitle,
  });

  factory QuizResultQuestion.fromJson(Map<String, dynamic> json) =>
      QuizResultQuestion(
        questionAttemptId: asString(json['question_attempt_id']),
        prompt: asString(json['prompt']),
        isCorrect: asBool(json['is_correct']),
        userAnswer: asStringOrNull(json['user_answer']),
        correctAnswer: asStringOrNull(json['correct_answer']),
        aiFeedback: asStringOrNull(json['ai_feedback']),
        grade: json['grade'] == null
            ? null
            : ReviewGrade.fromWire(json['grade']),
        nodeId: asStringOrNull(json['node_id']),
        nodeTitle: asStringOrNull(json['node_title']),
      );
}

class QuizWeakTopic {
  final String nodeId;
  final String title;
  final String? bucketName;
  final int comfort;
  final int priority;
  final int difficulty;

  const QuizWeakTopic({
    required this.nodeId,
    this.title = '',
    this.bucketName,
    this.comfort = 0,
    this.priority = 3,
    this.difficulty = 3,
  });

  factory QuizWeakTopic.fromJson(Map<String, dynamic> json) => QuizWeakTopic(
        nodeId: asString(json['node_id']),
        title: asString(json['title']),
        bucketName: asStringOrNull(json['bucket_name']),
        comfort: asInt(json['comfort']),
        priority: asInt(json['priority'], 3),
        difficulty: asInt(json['difficulty'], 3),
      );
}

class QuizComfortUpdate {
  final String nodeId;
  final String title;
  final int? comfortBefore;
  final int? comfortAfter;
  final ReviewGrade? grade;

  const QuizComfortUpdate({
    required this.nodeId,
    this.title = '',
    this.comfortBefore,
    this.comfortAfter,
    this.grade,
  });

  factory QuizComfortUpdate.fromJson(Map<String, dynamic> json) =>
      QuizComfortUpdate(
        nodeId: asString(json['node_id']),
        title: asString(json['title']),
        comfortBefore: asIntOrNull(json['comfort_before']),
        comfortAfter: asIntOrNull(json['comfort_after']),
        grade: json['grade'] == null
            ? null
            : ReviewGrade.fromWire(json['grade']),
      );

  /// True when the post-review comfort rose (drives the arrow tilt + copy).
  bool get bumpedUp => (comfortAfter ?? 0) >= (comfortBefore ?? 0);
}
