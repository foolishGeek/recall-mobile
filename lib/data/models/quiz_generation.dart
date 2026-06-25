// Recall - QuizGeneration - response from `quiz-generate` after S17 creates an
// in-progress attempt and returns redacted play-ready questions.

import 'json_utils.dart';
import 'quiz_question.dart';

class GeneratedQuizQuestion {
  final String questionAttemptId;
  final QuizQuestion question;

  /// True when this position already has a persisted answer (resume payload).
  final bool answered;

  const GeneratedQuizQuestion({
    required this.questionAttemptId,
    required this.question,
    this.answered = false,
  });

  factory GeneratedQuizQuestion.fromJson(Map<String, dynamic> json) =>
      GeneratedQuizQuestion(
        questionAttemptId: asString(json['question_attempt_id']),
        question: QuizQuestion.fromJson(json),
        answered: json['answered'] == true,
      );

  Map<String, dynamic> toJson() => {
        'question_attempt_id': questionAttemptId,
        'answered': answered,
        ...question.toJson(),
      };
}

class QuizGeneration {
  final String attemptId;
  final int? timerSec;
  final int questionCount;
  final List<GeneratedQuizQuestion> questions;

  const QuizGeneration({
    required this.attemptId,
    this.timerSec,
    required this.questionCount,
    required this.questions,
  });

  factory QuizGeneration.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((q) => GeneratedQuizQuestion.fromJson(
                  q.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .toList()
        : <GeneratedQuizQuestion>[];

    return QuizGeneration(
      attemptId: asString(json['attempt_id']),
      timerSec: asIntOrNull(json['timer_sec']),
      questionCount: asInt(json['question_count'], questions.length),
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempt_id': attemptId,
        'timer_sec': timerSec,
        'question_count': questionCount,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
