// Recall · time formatting. 12-hour clock, relative / due labels, month abbr.
// en-only for v1 — fixed formats are correct and deterministic.

class RecallTime {
  const RecallTime._();

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats [dt] as a 12-hour clock with AM/PM, e.g. "9:05 AM".
  static String clock12h(DateTime dt) {
    final hour24 = dt.hour;
    final period = hour24 < 12 ? 'AM' : 'PM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$m $period';
  }

  static String monthAbbr(int month) => _monthAbbr[(month - 1).clamp(0, 11)];

  /// Short relative past/future: "2h ago", "in 3d", "just now".
  static String relativeAgo(DateTime? at, {DateTime? now}) {
    if (at == null) return '';
    final n = now ?? DateTime.now();
    final diff = n.difference(at);
    if (diff.inSeconds.abs() < 60) return 'just now';
    if (diff.isNegative) {
      final ahead = at.difference(n);
      if (ahead.inHours < 1) return 'in ${ahead.inMinutes}m';
      if (ahead.inHours < 24) return 'in ${ahead.inHours}h';
      return 'in ${ahead.inDays}d';
    }
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays}d ago';
  }

  /// Due label for node lists: "New", "Due today", "Due tomorrow", "In 3d", "1d ago".
  static String dueLabel(DateTime? dueAt, {DateTime? now}) {
    if (dueAt == null) return 'New';
    final n = now ?? DateTime.now();
    final diff = n.difference(dueAt);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Due today';
      if (days == 1) return 'Due tomorrow';
      return 'In ${days}d';
    }
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  /// Subscription renew/expire line: "renews 12 Jan".
  static String? subscriptionRenewLabel(DateTime? expires, bool willRenew) {
    if (expires == null) return null;
    final d = expires.toLocal();
    final verb = willRenew ? 'renews' : 'expires';
    return '$verb ${d.day} ${monthAbbr(d.month)}';
  }

  /// Duration as m:ss or h:mm:ss.
  static String durationMmSs(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// File size as B / KB / MB.
  static String bytesLabel(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
