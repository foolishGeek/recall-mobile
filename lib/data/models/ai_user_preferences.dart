// Recall · AiUserPreferences — `ai_user_preferences` row [D-AI-8]. Learned,
// per-user style directives Aura injects into that user's prompts. Read-only on
// the client (writes go through ai_apply_suggestion / ai_clear_preferences).

import 'json_utils.dart';

class AiUserPreferences {
  final String userId;
  final Map<String, dynamic> styleDirectives;
  final List<String> customNotes;
  final DateTime? updatedAt;

  const AiUserPreferences({
    required this.userId,
    this.styleDirectives = const {},
    this.customNotes = const [],
    this.updatedAt,
  });

  bool get isEmpty => styleDirectives.isEmpty && customNotes.isEmpty;

  factory AiUserPreferences.fromJson(Map<String, dynamic> json) =>
      AiUserPreferences(
        userId: asString(json['user_id']),
        styleDirectives: asJsonMap(json['style_directives']),
        customNotes: asStringList(json['custom_notes']),
        updatedAt: asDateTime(json['updated_at']),
      );
}
