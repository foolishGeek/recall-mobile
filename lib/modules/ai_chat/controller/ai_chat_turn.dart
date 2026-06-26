// Recall · ephemeral AI-chat turn. v1 chat is in-memory only (no thread table
// [CANON §13.7]) — these turns live for the life of the controller and are never
// persisted. The user turn is a question bubble; the AI turn is an editorial
// answer with its source citations and the model that produced it.

import '../../../data/models/models.dart';

enum AiTurnRole { user, ai }

class AiChatTurn {
  final AiTurnRole role;
  final String text;
  final List<RagCitation> citations;
  final String? model;
  final DateTime createdAt;

  /// Set on AI turns so the user can rate the answer (thumbs) [D-AI-6].
  final String? interactionId;

  /// Local thumbs state: -1 (down) / 0 (none) / +1 (up). Mutable for the UI.
  int rating;

  AiChatTurn({
    required this.role,
    required this.text,
    this.citations = const [],
    this.model,
    this.interactionId,
    this.rating = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AiChatTurn.user(String text) =>
      AiChatTurn(role: AiTurnRole.user, text: text);

  factory AiChatTurn.ai({
    required String text,
    List<RagCitation> citations = const [],
    String? model,
    String? interactionId,
  }) =>
      AiChatTurn(
        role: AiTurnRole.ai,
        text: text,
        citations: citations,
        model: model,
        interactionId: interactionId,
      );

  bool get isUser => role == AiTurnRole.user;
}
