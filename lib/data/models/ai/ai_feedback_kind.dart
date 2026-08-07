// Recall · AiFeedbackKind. The feedback vocabulary `ai_record_feedback` accepts
// [D-AI-6]. Thumbs and suggestions keep their own RPCs; these are the passive
// signals we can read from ordinary use without asking the user anything.

enum AiFeedbackKind {
  /// The user tapped a source chip — a weak relevance label for that note.
  citationOpened('citation_opened'),

  /// The user copied the answer out — a weak positive.
  answerCopied('answer_copied'),

  /// The user kept AI text in their own note — the strongest positive there is.
  editAccepted('edit_accepted'),

  /// The user stopped the answer mid-delivery — they had read enough, or
  /// enough to know it was not what they wanted.
  streamAbandoned('stream_abandoned');

  const AiFeedbackKind(this.wireName);

  final String wireName;
}
