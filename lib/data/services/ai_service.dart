// Recall · AiService. Thin wrapper over the `ai-forge` Edge Function router and
// the standalone AI Edge Functions. Raw I/O only — no business rules (the gate,
// model routing, retrieval scope, and tier checks all live in the backend).
// Quota/gate errors surface as RepoException via SupabaseService.invokeFunction.

import 'package:get/get.dart';

import '../models/models.dart';
import 'supabase_service.dart';

class AiService extends GetxService {
  AiService(this._supabase);

  final SupabaseService _supabase;

  /// Calls the `ai-forge` router with `{ feature, payload }` and returns the raw
  /// JSON body. Feature-typed helpers below build on this.
  Future<Map<String, dynamic>> invokeForge(
    String feature, {
    Map<String, dynamic> payload = const {},
  }) {
    return _supabase.invokeFunction(
      'ai-forge',
      body: {'feature': feature, 'payload': payload},
    );
  }

  /// RAG chat over the user's notes within the active-bucket scope. Empty corpus
  /// returns an answer with `model == null` (no charge, server-decided).
  ///
  /// During a premium fair-use cooldown the server ASKS before charging: the
  /// default call yields a 429 `ai_cooldown` so the UI can show the interstitial.
  /// Pass [spendCredit] = true on an explicit "Continue with 1 credit" retry to
  /// authorise the credit deduction (or a 403 `insufficient_credits`) [D-AI-1].
  Future<RagChatResult> ragChat({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
    bool spendCredit = false,
  }) async {
    final body = await invokeForge('rag_chat', payload: {
      'question': question,
      if (bucketIds.isNotEmpty) 'bucket_ids': bucketIds,
      if (nodeIds.isNotEmpty) 'node_ids': nodeIds,
      if (spendCredit) 'spend_credit': true,
    });
    return RagChatResult.fromJson(body);
  }

  /// Summarize a node or a bucket. Throws RepoException(`empty_context`) when
  /// there's no text to summarize.
  Future<SummarizeResult> summarize({
    required String scope, // 'node' | 'bucket'
    String? nodeId,
    String? bucketId,
  }) async {
    final body = await invokeForge('summarize', payload: {
      'scope': scope,
      if (nodeId != null) 'node_id': nodeId,
      if (bucketId != null) 'bucket_id': bucketId,
    });
    return SummarizeResult.fromJson(body);
  }

  /// AI overview for a node (separate quota). Cached by content_hash server-side.
  Future<EvaluateResult> evaluate({required String nodeId}) async {
    final body = await invokeForge('evaluate', payload: {'node_id': nodeId});
    return EvaluateResult.fromJson(body);
  }

  /// Grade a short answer (premium). Ungradable input → `again`.
  Future<QuizGradeResult> quizGrade({
    required String nodeId,
    required String question,
    required String referenceAnswer,
    required String userAnswer,
    required String questionType,
    String? gradingRubric,
  }) async {
    final body = await invokeForge('quiz_grade', payload: {
      'node_id': nodeId,
      'question': question,
      'reference_answer': referenceAnswer,
      'user_answer': userAnswer,
      'question_type': questionType,
      if (gradingRubric != null) 'grading_rubric': gradingRubric,
    });
    return QuizGradeResult.fromJson(body);
  }

  /// Fetch a link preview (7-field) via the standalone `link-preview` function.
  Future<LinkPreview> linkPreview(String url) async {
    final body = await _supabase.invokeFunction('link-preview', body: {'url': url});
    return LinkPreview.fromJson(body);
  }

  /// Extract text from an uploaded PDF (≤20 MB) via `extract-pdf-text`. Returns
  /// the raw `{ extracted_text, page_count }` body; the embed pipeline runs
  /// server-side off the resulting content_hash change.
  Future<Map<String, dynamic>> extractPdfText(String storagePath) {
    return _supabase.invokeFunction(
      'extract-pdf-text',
      body: {'storage_path': storagePath},
    );
  }
}
