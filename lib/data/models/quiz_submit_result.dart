// Recall · QuizSubmitResult — typed response from the `quiz-submit-answer` EF.
// Correctness lives in Results, so the play screen only uses `pending` (short
// answer awaiting AI) and `flashcardBack` (reveal). `grade`/`isCorrect` are
// stored server-side and surfaced again in S19 results.

import 'enums.dart';
import 'json_utils.dart';

class QuizSubmitResult {
  final bool isCorrect;
  final ReviewGrade? grade;
  final String? aiFeedback;
  final String? flashcardBack;
  final bool pending;

  const QuizSubmitResult({
    this.isCorrect = false,
    this.grade,
    this.aiFeedback,
    this.flashcardBack,
    this.pending = false,
  });

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) =>
      QuizSubmitResult(
        isCorrect: asBool(json['is_correct']),
        grade: json['grade'] == null ? null : ReviewGrade.fromWire(json['grade']),
        aiFeedback: asStringOrNull(json['ai_feedback']),
        flashcardBack: asStringOrNull(json['flashcard_back']),
        pending: asBool(json['pending']),
      );
}
