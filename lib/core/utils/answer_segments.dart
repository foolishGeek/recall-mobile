// Recall · split an Aura answer into tappable segments for "Update note".
// Prefer natural blocks (paragraphs / bullets); fall back to sentences so a
// wall of prose stays selectable without feeling surgical.

/// Breaks [answer] into user-facing chunks (order preserved, blanks dropped).
List<String> splitAnswerSegments(String answer) {
  final trimmed = answer.trim();
  if (trimmed.isEmpty) return const [];

  // Prefer paragraph breaks.
  final paragraphs = trimmed
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  if (paragraphs.length > 1) {
    return paragraphs.expand(_expandBlock).toList();
  }

  // Single block — expand bullets / sentences.
  return _expandBlock(paragraphs.single).toList();
}

Iterable<String> _expandBlock(String block) {
  final lines = block
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  // Multi-line list → one segment per bullet / numbered item.
  final bulletish = lines.every(_looksLikeListItem);
  if (lines.length > 1 && bulletish) {
    return lines;
  }

  // Long single prose → sentence segments (keep short blocks whole).
  if (lines.length == 1 && block.length > 160) {
    final sentences = _splitSentences(block);
    if (sentences.length > 1) return sentences;
  }

  return [block];
}

bool _looksLikeListItem(String line) {
  return RegExp(r'^([-*•]|\d+[.)])\s+').hasMatch(line);
}

List<String> _splitSentences(String text) {
  final out = <String>[];
  final re = RegExp(r'[^.!?]+[.!?]+(?:\s+|$)|[^.!?]+$');
  for (final m in re.allMatches(text)) {
    final s = m.group(0)!.trim();
    if (s.isNotEmpty) out.add(s);
  }
  return out;
}
