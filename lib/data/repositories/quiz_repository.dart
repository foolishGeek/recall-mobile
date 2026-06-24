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
