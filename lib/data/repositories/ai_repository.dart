// Recall · AiRepository. Reads AI evaluations + credit ledger (both written
// server-side) and wraps AiService for `ai-forge` calls. Feature-typed returns
// land in S06; the invoke seam returns the raw EF body for now.

import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class AiRepository extends BaseRepository {
  AiRepository(SupabaseService supabase, this._ai) : super(supabase, 'ai');

  final AiService _ai;

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
  Future<RagChatResult> ragChat({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
  }) =>
      guard(() => _ai.ragChat(
            question: question,
            bucketIds: bucketIds,
            nodeIds: nodeIds,
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

  /// Fetch a 7-field link preview.
  Future<LinkPreview> linkPreview(String url) =>
      guard(() => _ai.linkPreview(url));

  /// Extract text from an uploaded PDF (≤20 MB); embed runs server-side after.
  Future<Map<String, dynamic>> extractPdfText(String storagePath) =>
      guard(() => _ai.extractPdfText(storagePath));
}
