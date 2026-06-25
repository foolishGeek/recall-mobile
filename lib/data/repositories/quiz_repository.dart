// Recall · QuizRepository. Quiz configs, attempts, and per-question attempts.
// `question_count` is denormalized on attempts [D-SCHEMA-5]. Returns models only.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class QuizRepository extends BaseRepository {
  QuizRepository(SupabaseService supabase) : super(supabase, 'quiz');

  Future<QuizConfig> createConfig(QuizConfig config) => guard(() async {
        final row = await supabase
            .from('quiz_configs')
            .insert(writable(config.toJson(), drop: {'id', 'created_at'}))
            .select()
            .single();
        return QuizConfig.fromJson(row);
      });

  Future<QuizAttempt> createAttempt(QuizAttempt attempt) => guard(() async {
        final row = await supabase
            .from('quiz_attempts')
            .insert(writable(attempt.toJson(), drop: {'id', 'created_at'}))
            .select()
            .single();
        return QuizAttempt.fromJson(row);
      });

  Future<QuizGeneration> generate(String configId) => guard(() async {
        final body = await supabase.invokeFunction(
          'quiz-generate',
          body: {'config_id': configId},
        );
        return QuizGeneration.fromJson(body);
      });

  /// Redacted questions + answered flags for resuming an in-progress attempt.
  /// The answer key is never exposed; the server holds it [D-QUIZ-1].
  Future<QuizGeneration> resumeAttempt(String attemptId) => guard(() async {
        final body = await supabase.invokeFunction(
          'quiz-attempt',
          body: {'attempt_id': attemptId},
        );
        return QuizGeneration.fromJson(body);
      });

  /// Submits one answer; grading is server-authoritative. Idempotent per
  /// question attempt — a replay returns the stored grade [D-EF-8].
  Future<QuizSubmitResult> submitAnswer({
    required String attemptId,
    required String questionAttemptId,
    int? selectedIndex,
    String? userAnswer,
    ReviewGrade? flashcardGrade,
    bool revealOnly = false,
    int? responseMs,
    bool timedOut = false,
  }) =>
      guard(() async {
        final body = <String, dynamic>{
          'attempt_id': attemptId,
          'question_attempt_id': questionAttemptId,
          'reveal_only': revealOnly,
          'timed_out': timedOut,
          if (selectedIndex != null) 'selected_index': selectedIndex,
          if (userAnswer != null) 'user_answer': userAnswer,
          if (flashcardGrade != null) 'flashcard_grade': flashcardGrade.wire,
          if (responseMs != null) 'response_ms': responseMs,
        };
        final res = await supabase.invokeFunction(
          'quiz-submit-answer',
          body: body,
        );
        return QuizSubmitResult.fromJson(res);
      });

  /// The latest in-progress attempt for the user, if any (drives the Quiz Home
  /// "Resume" entry). Returns null when there is nothing to resume.
  Future<QuizAttempt?> fetchInProgressAttempt(String userId) => guard(() async {
        final rows = await supabase
            .from('quiz_attempts')
            .select()
            .eq('user_id', userId)
            .eq('status', QuizAttemptStatus.inProgress.wire)
            .order('created_at', ascending: false)
            .limit(1);
        if (rows.isEmpty) return null;
        return QuizAttempt.fromJson(Map<String, dynamic>.from(rows.first));
      });

  Future<QuizAttempt> updateAttempt(String id, Map<String, dynamic> changes) =>
      guard(() async {
        final row = await supabase
            .from('quiz_attempts')
            .update(changes)
            .eq('id', id)
            .select()
            .single();
        return QuizAttempt.fromJson(row);
      });

  /// Recent completed quizzes for the "Recent quizzes" chips [D-UI-2].
  Future<List<QuizAttempt>> fetchRecentAttempts(String userId,
          {int limit = 20}) =>
      guard(() async {
        final rows = await supabase
            .from('quiz_attempts')
            .select()
            .eq('user_id', userId)
            .eq('status', QuizAttemptStatus.completed.wire)
            .order('completed_at', ascending: false)
            .limit(limit);
        return mapList(rows, QuizAttempt.fromJson);
      });

  Future<List<QuizQuestionAttempt>> fetchQuestionAttempts(String attemptId) =>
      guard(() async {
        final rows = await supabase
            .from('quiz_question_attempts')
            .select()
            .eq('attempt_id', attemptId)
            .order('position', ascending: true);
        return mapList(rows, QuizQuestionAttempt.fromJson);
      });
}
