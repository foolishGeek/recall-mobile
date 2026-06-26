// Recall · Typed results for the `ai-forge` feature calls (S06). These mirror the
// Edge Function response shapes; the client only renders them (the backend owns
// all decisioning). Errors surface as RepoException via SupabaseService.

import 'enums.dart';
import 'json_utils.dart';

/// Provider token usage echoed by generative features (informational).
class AiUsage {
  final int inputTokens;
  final int outputTokens;

  const AiUsage({this.inputTokens = 0, this.outputTokens = 0});

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
        inputTokens: asInt(json['input_tokens']),
        outputTokens: asInt(json['output_tokens']),
      );
}

/// A cited source in a RAG answer.
class RagCitation {
  final String nodeId;
  final String title;
  final String snippet;

  const RagCitation({required this.nodeId, this.title = '', this.snippet = ''});

  factory RagCitation.fromJson(Map<String, dynamic> json) => RagCitation(
        nodeId: asString(json['node_id']),
        title: asString(json['title']),
        snippet: asString(json['snippet']),
      );
}

/// `rag_chat` response. [model] is null when the corpus was empty (no LLM call).
/// [interactionId] lets the client attach a rating/suggestion later [D-AI-6].
class RagChatResult {
  final String answer;
  final List<RagCitation> citations;
  final String? model;
  final AiUsage? usage;
  final String? interactionId;

  const RagChatResult({
    required this.answer,
    this.citations = const [],
    this.model,
    this.usage,
    this.interactionId,
  });

  factory RagChatResult.fromJson(Map<String, dynamic> json) => RagChatResult(
        answer: asString(json['answer']),
        citations: (json['citations'] is List)
            ? (json['citations'] as List)
                .whereType<Map>()
                .map((e) => RagCitation.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        model: asStringOrNull(json['model']),
        usage: json['usage'] is Map
            ? AiUsage.fromJson(Map<String, dynamic>.from(json['usage'] as Map))
            : null,
        interactionId: asStringOrNull(json['interaction_id']),
      );
}

/// `summarize` response: bullet points + key theme labels.
class SummarizeResult {
  final List<String> summary;
  final List<String> keyThemes;
  final String? model;
  final AiUsage? usage;

  const SummarizeResult({
    this.summary = const [],
    this.keyThemes = const [],
    this.model,
    this.usage,
  });

  factory SummarizeResult.fromJson(Map<String, dynamic> json) => SummarizeResult(
        summary: asStringList(json['summary']),
        keyThemes: asStringList(json['key_themes']),
        model: asStringOrNull(json['model']),
        usage: json['usage'] is Map
            ? AiUsage.fromJson(Map<String, dynamic>.from(json['usage'] as Map))
            : null,
      );
}

/// `evaluate` (AI overview) response; [cached] true when served from cache.
/// [suggestedMarkdown] is an improved rewrite of the note for the diff view.
class EvaluateResult {
  final int? qualityScore;
  final int? suggestedComfort;
  final int? suggestedDifficulty;
  final String? feedback;
  final String? suggestedMarkdown;
  final String? model;
  final bool cached;
  final String? interactionId;

  const EvaluateResult({
    this.qualityScore,
    this.suggestedComfort,
    this.suggestedDifficulty,
    this.feedback,
    this.suggestedMarkdown,
    this.model,
    this.cached = false,
    this.interactionId,
  });

  factory EvaluateResult.fromJson(Map<String, dynamic> json) => EvaluateResult(
        qualityScore: asIntOrNull(json['quality_score']),
        suggestedComfort: asIntOrNull(json['suggested_comfort']),
        suggestedDifficulty: asIntOrNull(json['suggested_difficulty']),
        feedback: asStringOrNull(json['feedback']),
        suggestedMarkdown: asStringOrNull(json['suggested_markdown']),
        model: asStringOrNull(json['model']),
        cached: asBool(json['cached']),
        interactionId: asStringOrNull(json['interaction_id']),
      );
}

/// `quiz_grade` response. [suggestedGrade] feeds the review grade buttons.
class QuizGradeResult {
  final bool isCorrect;
  final ReviewGrade suggestedGrade;
  final String? feedback;
  final String? model;

  const QuizGradeResult({
    required this.isCorrect,
    required this.suggestedGrade,
    this.feedback,
    this.model,
  });

  factory QuizGradeResult.fromJson(Map<String, dynamic> json) => QuizGradeResult(
        isCorrect: asBool(json['is_correct']),
        suggestedGrade: ReviewGrade.fromWire(json['suggested_grade']),
        feedback: asStringOrNull(json['feedback']),
        model: asStringOrNull(json['model']),
      );
}
