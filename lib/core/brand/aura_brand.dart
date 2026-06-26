// Recall · Aura brand [D-AI-?]. The AI persona is always presented as "Aura"
// on the frontend; raw model labels (Claude/Gemini/GPT) are never shown. The
// server still routes to the best model per tier — that's an implementation
// detail the user never sees.

class AuraBrand {
  AuraBrand._();

  /// Short name shown almost everywhere.
  static const String name = 'Aura';

  /// Full lockup for headers / first mentions.
  static const String full = 'Aura by Recall';

  /// Calm one-liner about how Aura answers (notes-first, blended).
  static const String groundedTagline = 'Grounded in your notes, enriched by Aura';
}
