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

/// Append any standalone URLs from [before] that are missing in [after], so an
/// Aura rewrite never drops LINKED / WATCH cards.
String mergeStandaloneUrls(String? before, String after) {
  final original = standaloneUrls(before);
  if (original.isEmpty) return after;

  final present = standaloneUrls(after).map(_normalizeUrl).toSet();
  final missing =
      original.where((u) => !present.contains(_normalizeUrl(u))).toList();
  if (missing.isEmpty) return after;

  final trimmed = after.replaceFirst(RegExp(r'\s+$'), '');
  final block = missing.join('\n');
  if (trimmed.isEmpty) return block;
  return '$trimmed\n\n$block';
}

/// Replace the first standalone URL line matching [from] with [to]. Leaves the
/// rest of the markdown untouched. Returns [md] unchanged when [from] is absent.
String replaceStandaloneUrl(String? md, String from, String to) {
  if (md == null || md.isEmpty) return md ?? '';
  final fromKey = _normalizeUrl(from);
  final lines = md.split('\n');
  var replaced = false;
  for (var i = 0; i < lines.length; i++) {
    final m = _urlLineRegex.firstMatch(lines[i]);
    if (m == null) continue;
    if (_normalizeUrl(m.group(1)!) != fromKey) continue;
    lines[i] = to.trim();
    replaced = true;
    break;
  }
  return replaced ? lines.join('\n') : md;
}

String _normalizeUrl(String u) =>
    u.trim().replaceAll(RegExp(r'/+$'), '').toLowerCase();

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

/// Host without leading www — for quiet suggestion labels.
String urlDomain(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return url.trim();
  return uri.host.replaceFirst(RegExp(r'^www\.'), '');
}
