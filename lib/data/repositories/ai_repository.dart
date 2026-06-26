// Recall · AiRepository. Reads AI evaluations + credit ledger (both written
// server-side) and wraps AiService for `ai-forge` calls. Feature-typed returns
// land in S06; the invoke seam returns the raw EF body for now.

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class AiRepository extends BaseRepository {
  AiRepository(SupabaseService supabase, this._ai, this._local)
      : super(supabase, 'ai');

  final AiService _ai;
  final LocalStore _local;

  /// Latest cached AI overview for a node (`node_ai_evaluations`).
  Future<AiEvaluation?> fetchLatestEvaluation(String nodeId) => guard(() async {
        final row = await supabase
            .from('node_ai_evaluations')
            .select()
            .eq('node_id', nodeId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return row == null ? null : AiEvaluation.fromJson(row);
      });

  Future<List<AiCreditLedgerEntry>> fetchCreditLedger(String userId,
          {int limit = 50}) =>
      guard(() async {
        final rows = await supabase
            .from('ai_credit_ledger')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return mapList(rows, AiCreditLedgerEntry.fromJson);
      });

  /// Calls the `ai-forge` router (raw body). Errors map to RepoException inside
  /// SupabaseService.invokeFunction; `guard` also tags Sentry with `feature: ai`.
  Future<Map<String, dynamic>> invokeForge(
    String feature, {
    Map<String, dynamic> payload = const {},
  }) =>
      guard(() => _ai.invokeForge(feature, payload: payload));

  /// RAG chat over the user's notes (active-bucket scope resolved server-side).
  /// [spendCredit] authorises a credit deduction during a premium cooldown
  /// (set only on an explicit "Continue with 1 credit" retry) [D-AI-1].
  Future<RagChatResult> ragChat({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
    bool spendCredit = false,
  }) =>
      guard(() => _ai.ragChat(
            question: question,
            bucketIds: bucketIds,
            nodeIds: nodeIds,
            spendCredit: spendCredit,
          ));

  /// Summarize a node or bucket.
  Future<SummarizeResult> summarize({
    required String scope,
    String? nodeId,
    String? bucketId,
  }) =>
      guard(() => _ai.summarize(scope: scope, nodeId: nodeId, bucketId: bucketId));

  /// Generate (or return cached) AI overview for a node.
  Future<EvaluateResult> evaluate(String nodeId) =>
      guard(() => _ai.evaluate(nodeId: nodeId));

  /// Grade a short answer (premium).
  Future<QuizGradeResult> quizGrade({
    required String nodeId,
    required String question,
    required String referenceAnswer,
    required String userAnswer,
    required String questionType,
    String? gradingRubric,
  }) =>
      guard(() => _ai.quizGrade(
            nodeId: nodeId,
            question: question,
            referenceAnswer: referenceAnswer,
            userAnswer: userAnswer,
            questionType: questionType,
            gradingRubric: gradingRubric,
          ));

  /// Attach a thumbs rating (+ optional reason) to an AI interaction [D-AI-6].
  /// rating: -1 (down) / 0 (clear) / +1 (up).
  Future<bool> rateInteraction(String interactionId, int rating,
          {String? reason}) =>
      guard(() async {
        final res = await supabase.rpc('ai_rate_interaction', params: {
          'p_interaction': interactionId,
          'p_rating': rating,
          'p_reason': reason,
        });
        return res == true;
      });

  /// Queue-aware rating: tries the live RPC and, when offline, enqueues the
  /// thumbs signal locally for replay on reconnect [D-OFF-1]. Never throws.
  Future<bool> submitRating(String interactionId, int rating,
      {String? reason}) async {
    try {
      return await rateInteraction(interactionId, rating, reason: reason);
    } on RepoException catch (e) {
      if (e.isOffline) {
        await _local.enqueueAiFeedback({
          'type': 'rate',
          'interaction_id': interactionId,
          'rating': rating,
          'reason': reason,
        });
      }
      return false;
    }
  }

  /// Queue-aware suggestion: returns the merged directives when online (so the
  /// UI can acknowledge what changed), or an empty map when queued offline.
  Future<Map<String, dynamic>?> submitSuggestion(
    String suggestion, {
    int rating = 0,
    String? interactionId,
  }) async {
    final text = suggestion.trim();
    if (text.isEmpty) return null;
    try {
      return await applySuggestion(text,
          rating: rating, interactionId: interactionId);
    } on RepoException catch (e) {
      if (e.isOffline) {
        await _local.enqueueAiFeedback({
          'type': 'suggest',
          'suggestion': text,
          'rating': rating,
          'interaction_id': interactionId,
        });
        return const {};
      }
      return null;
    }
  }

  /// Apply a free-text suggestion → per-user style directives [D-AI-8].
  /// Returns the merged directives map so the UI can confirm what changed.
  Future<Map<String, dynamic>> applySuggestion(
    String suggestion, {
    int rating = 0,
    String? interactionId,
  }) =>
      guard(() async {
        final res = await supabase.rpc('ai_apply_suggestion', params: {
          'p_suggestion': suggestion,
          'p_rating': rating,
          'p_interaction': interactionId,
        });
        return res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
      });

  /// Current learned Aura preferences for transparency/control.
  Future<AiUserPreferences?> fetchPreferences(String userId) => guard(() async {
        final row = await supabase
            .from('ai_user_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        return row == null ? null : AiUserPreferences.fromJson(row);
      });

  /// Clear all learned Aura preferences for the current user.
  Future<void> clearPreferences() => guard(() async {
        await supabase.rpc('ai_clear_preferences');
      });

  /// Ranked weak skills (nodes) for the re-learning nudge [D-AI-9].
  Future<List<RelearnSkill>> fetchRelearnSkills({int limit = 12}) =>
      guard(() async {
        final rows = await supabase
            .from('v_relearn_skills')
            .select()
            .order('weakness_score', ascending: false)
            .limit(limit);
        return mapList(rows, RelearnSkill.fromJson);
      });

  /// Top weak node ids to seed a focused review/quiz session.
  Future<List<String>> buildRelearnSession(
          {int limit = 20, List<String>? bucketIds}) =>
      guard(() async {
        final res = await supabase.rpc('build_relearn_session', params: {
          'p_limit': limit,
          'p_bucket_ids': bucketIds,
        });
        return res is List ? res.map((e) => e.toString()).toList() : <String>[];
      });

  /// Fetch a 7-field link preview.
  Future<LinkPreview> linkPreview(String url) =>
      guard(() => _ai.linkPreview(url));

  /// Extract text from an uploaded PDF (≤20 MB); embed runs server-side after.
  Future<Map<String, dynamic>> extractPdfText(String storagePath) =>
      guard(() => _ai.extractPdfText(storagePath));
}
