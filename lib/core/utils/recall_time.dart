// Recall · time formatting. 12-hour clock with AM/PM for user-facing drop times
// — e.g. 14:05 → "2:05 PM", 00:30 → "12:30 AM". No intl dependency; the app is
// en-only for v1, so a fixed format is correct and deterministic.

class RecallTime {
  const RecallTime._();

  /// Formats [dt] as a 12-hour clock with AM/PM, e.g. "9:05 AM". Callers pass a
  /// local `DateTime` (use `.toLocal()` first).
  static String clock12h(DateTime dt) {
    final hour24 = dt.hour;
    final period = hour24 < 12 ? 'AM' : 'PM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$m $period';
  }
}
