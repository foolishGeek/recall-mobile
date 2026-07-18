// Recall · optional closer-match URL from Aura evaluate. Never auto-applied;
// the detail view shows a quiet Use / Dismiss nudge under the LINKED/WATCH card.

import 'json_utils.dart';

class LinkSuggestion {
  final String currentUrl;
  final String suggestedUrl;
  final String label;

  const LinkSuggestion({
    required this.currentUrl,
    required this.suggestedUrl,
    this.label = '',
  });

  factory LinkSuggestion.fromJson(Map<String, dynamic> json) => LinkSuggestion(
        currentUrl: asString(json['current_url']),
        suggestedUrl: asString(json['suggested_url']),
        label: asString(json['label']),
      );

  Map<String, dynamic> toJson() => {
        'current_url': currentUrl,
        'suggested_url': suggestedUrl,
        'label': label,
      };
}

List<LinkSuggestion> linkSuggestionsFromJson(Object? raw) {
  if (raw is! List) return const [];
  final out = <LinkSuggestion>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final s = LinkSuggestion.fromJson(Map<String, dynamic>.from(item));
    if (s.currentUrl.isEmpty || s.suggestedUrl.isEmpty) continue;
    out.add(s);
    if (out.length >= 2) break;
  }
  return out;
}
