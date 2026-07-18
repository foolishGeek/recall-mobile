// Recall · note link helpers. Links + YouTube URLs added via the note editor's
// CTAs are stored as standalone lines at the end of the markdown body. These
// helpers parse/strip them and validate URLs, so the editor and the detail view
// agree on exactly what counts as a "reference link".

final RegExp _urlLineRegex = RegExp(r'^\s*(https?:\/\/\S+)\s*$');

/// True when a whole line is just a URL (a reference link, not inline prose).
bool isUrlLine(String line) => _urlLineRegex.hasMatch(line);

/// URLs that sit on their own line in [md] — i.e. reference links/videos added
/// via the editor CTAs, in document order.
List<String> standaloneUrls(String? md) {
  if (md == null || md.isEmpty) return const [];
  final out = <String>[];
  for (final line in md.split('\n')) {
    final m = _urlLineRegex.firstMatch(line);
    if (m != null) out.add(m.group(1)!);
  }
  return out;
}

/// [md] with standalone-URL lines removed, so the body renders as clean text
/// (the URLs show as rich cards instead).
String stripStandaloneUrls(String? md) {
  if (md == null || md.isEmpty) return '';
  final kept = md.split('\n').where((l) => !isUrlLine(l)).toList();
  return kept.join('\n').trim();
}

/// A valid http/https URL with a host.
bool isValidHttpUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
}

/// A valid URL that points at YouTube.
bool isYoutubeUrl(String url) {
  if (!isValidHttpUrl(url)) return false;
  final host = Uri.parse(url.trim()).host.toLowerCase();
  return host.contains('youtube.com') || host.contains('youtu.be');
}
