// Human-readable mapping of Aura's learned style directives [D-AI-8]. The
// backend (ai_apply_suggestion) maps free-text suggestions to a small set of
// directive keys; this turns those keys into calm, plain-English copy for the
// acknowledgment toast and the "Aura preferences" view.

import 'aura_brand.dart';

class AuraPrefs {
  AuraPrefs._();

  /// One-line confirmation shown right after a suggestion is sent.
  static String acknowledge(Map<String, dynamic> directives) {
    final lines = describe(directives);
    if (lines.isEmpty) {
      return 'Thanks — ${AuraBrand.name} will keep that in mind.';
    }
    return 'Got it — ${AuraBrand.name} will ${_joinLower(lines)}.';
  }

  /// Bullet-friendly descriptions for the transparency/control view.
  static List<String> describe(Map<String, dynamic> directives) {
    final out = <String>[];
    switch (directives['length']) {
      case 'concise':
        out.add('Keep answers concise');
        break;
      case 'detailed':
        out.add('Give fuller answers');
        break;
    }
    if (directives['examples'] == true) out.add('Include examples');
    switch (directives['depth']) {
      case 'deep':
        out.add('Go deeper on detail');
        break;
      case 'light':
        out.add('Stay high-level');
        break;
    }
    switch (directives['tone']) {
      case 'plain':
        out.add('Use plain language');
        break;
      case 'formal':
        out.add('Keep a formal tone');
        break;
    }
    if (directives['format'] == 'steps') out.add('Prefer step-by-step answers');
    return out;
  }

  /// Full transparency list for the Tune sheet: mapped directives first, then
  /// the user's raw suggestions (newest first), skipping blanks and anything
  /// that already reads the same as a mapped directive line.
  static List<String> learnedLines({
    required Map<String, dynamic> styleDirectives,
    required List<String> customNotes,
  }) {
    final lines = describe(styleDirectives);
    final seen = lines.map((l) => l.toLowerCase()).toSet();
    for (final note in customNotes.reversed) {
      final t = note.trim();
      if (t.isEmpty) continue;
      if (seen.add(t.toLowerCase())) lines.add(t);
    }
    return lines;
  }

  static String _joinLower(List<String> lines) {
    final lowered = lines.map((l) => l[0].toLowerCase() + l.substring(1));
    if (lowered.length == 1) return lowered.first;
    final all = lowered.toList();
    final last = all.removeLast();
    return '${all.join(', ')} and $last';
  }
}
