// Recall · AiService. Thin wrapper over the `ai-forge` Edge Function router and
// the standalone AI Edge Functions. Raw I/O only — no business rules (the gate,
// model routing, retrieval scope, and tier checks all live in the backend).
// Quota/gate errors surface as RepoException via SupabaseService.invokeFunction.

import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_env.dart';
import '../../models/models.dart';
import '../platform/supabase_service.dart';
import '../shared/repo_exception.dart';

class AiService extends GetxService {
  AiService(this._supabase);

  final SupabaseService _supabase;
  static const _uuid = Uuid();

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

  Map<String, dynamic> _chatPayload({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
    bool spendCredit = false,
    String? conversationId,
    String? replacesInteractionId,
    String? clientRequestId,
  }) =>
      {
        'question': question,
        if (bucketIds.isNotEmpty) 'bucket_ids': bucketIds,
        if (nodeIds.isNotEmpty) 'node_ids': nodeIds,
        if (spendCredit) 'spend_credit': true,
        if (conversationId != null) 'conversation_id': conversationId,
        if (replacesInteractionId != null)
          'replaces_interaction_id': replacesInteractionId,
        if (clientRequestId != null) 'client_request_id': clientRequestId,
      };

  /// Buffered RAG chat (fallback / non-Ask-Aura callers). Prefer [ragChatStream]
  /// for the chat screen — tokens arrive as the model writes them.
  Future<RagChatResult> ragChat({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
    bool spendCredit = false,
    String? conversationId,
    String? replacesInteractionId,
  }) async {
    final body = await invokeForge(
      'rag_chat',
      payload: _chatPayload(
        question: question,
        bucketIds: bucketIds,
        nodeIds: nodeIds,
        spendCredit: spendCredit,
        conversationId: conversationId,
        replacesInteractionId: replacesInteractionId,
        clientRequestId: _uuid.v4(),
      ),
    );
    return RagChatResult.fromJson(body);
  }

  /// Streaming RAG chat via SSE (`rag_chat_stream`).
  ///
  /// Denials before the first byte are JSON errors (same RepoException codes as
  /// [ragChat]). Once open, [onOpen] may receive the conversation id, [onDelta]
  /// receives each visible token; the Future completes with the closing `done`
  /// frame. Close [client] to cancel.
  Future<RagChatResult> ragChatStream({
    required String question,
    List<String> bucketIds = const [],
    List<String> nodeIds = const [],
    bool spendCredit = false,
    String? conversationId,
    String? replacesInteractionId,
    void Function(String? conversationId)? onOpen,
    required void Function(String delta) onDelta,
    http.Client? client,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const RepoException(
        RepoErrorCode.unauthorized,
        'Sign in to ask Aura.',
      );
    }

    final uri = Uri.parse('${AppEnv.supabaseUrl}/functions/v1/ai-forge');
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': AppEnv.supabaseAnonKey,
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({
          'feature': 'rag_chat_stream',
          'payload': _chatPayload(
            question: question,
            bucketIds: bucketIds,
            nodeIds: nodeIds,
            spendCredit: spendCredit,
            conversationId: conversationId,
            replacesInteractionId: replacesInteractionId,
            clientRequestId: _uuid.v4(),
          ),
        });

      final streamed = await httpClient.send(request);
      final contentType = streamed.headers['content-type'] ?? '';

      // Pre-stream denials stay JSON with a real status — map them the same way
      // as invokeFunction so the cooldown / paywall sheets still open.
      if (!contentType.contains('text/event-stream')) {
        final raw = await streamed.stream.bytesToString();
        Map<String, dynamic> body = {};
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            body = decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {
          body = {'message': raw};
        }
        throw RepoException(
          RepoErrorCode.fromWire(body['error']?.toString()),
          body['message']?.toString() ?? 'Could not start the answer.',
          extra: body,
        );
      }

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw RepoException(
          RepoErrorCode.providerError,
          'Stream failed (${streamed.statusCode}).',
        );
      }

      return await _readSse(streamed.stream, onDelta, onOpen);
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  Future<RagChatResult> _readSse(
    Stream<List<int>> byteStream,
    void Function(String delta) onDelta,
    void Function(String? conversationId)? onOpen,
  ) async {
    RagChatResult? done;
    String? midError;
    var event = '';
    final dataBuf = StringBuffer();
    var carry = '';

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      carry += chunk;
      var cut = carry.indexOf('\n');
      while (cut != -1) {
        var line = carry.substring(0, cut);
        carry = carry.substring(cut + 1);
        cut = carry.indexOf('\n');
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);

        if (line.isEmpty) {
          if (event.isNotEmpty && dataBuf.isNotEmpty) {
            final payload = dataBuf.toString();
            dataBuf.clear();
            final name = event;
            event = '';
            final parsed = _parseJsonMap(payload);
            if (name == 'open') {
              final id = parsed['conversation_id']?.toString();
              onOpen?.call(id != null && id.isNotEmpty ? id : null);
            } else if (name == 'delta') {
              final t = parsed['t']?.toString() ?? '';
              if (t.isNotEmpty) onDelta(t);
            } else if (name == 'done') {
              done = RagChatResult.fromJson(parsed);
            } else if (name == 'error') {
              // partial:true means we still get a done with the truncated text.
              if (parsed['partial'] != true) {
                midError = parsed['message']?.toString() ??
                    'The answer stopped early.';
              }
            }
          } else {
            event = '';
            dataBuf.clear();
          }
          continue;
        }

        if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          if (dataBuf.isNotEmpty) dataBuf.write('\n');
          dataBuf.write(line.substring(5).trimLeft());
        }
      }
    }

    if (done != null) return done;
    throw RepoException(
      RepoErrorCode.providerError,
      midError ?? 'The answer stopped early. Try again.',
    );
  }

  Map<String, dynamic> _parseJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return const {};
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

  /// AI overview for a node (separate quota). Cached by content_hash server-side
  /// unless [forceRefresh] is true (Regenerate).
  Future<EvaluateResult> evaluate({
    required String nodeId,
    bool forceRefresh = false,
  }) async {
    final body = await invokeForge('evaluate', payload: {
      'node_id': nodeId,
      if (forceRefresh) 'force_refresh': true,
    });
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

  /// Bucket-aware starter questions for the Ask Aura empty state.
  Future<SuggestPromptsResult> suggestPrompts({
    List<String> bucketIds = const [],
  }) async {
    final body = await invokeForge('suggest_prompts', payload: {
      if (bucketIds.isNotEmpty) 'bucket_ids': bucketIds,
    });
    return SuggestPromptsResult.fromJson(body);
  }

  /// Fetch a link preview (7-field) via the standalone `link-preview` function.
  Future<LinkPreview> linkPreview(String url) async {
    final body =
        await _supabase.invokeFunction('link-preview', body: {'url': url});
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
