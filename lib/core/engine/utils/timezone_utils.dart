// Recall · timezone helpers for local-day boundaries [D-ENG-5 / edge case 9].

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzReady = false;

void ensureTimezoneData() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

tz.Location locationFor(String timezone) {
  ensureTimezoneData();
  try {
    return tz.getLocation(timezone);
  } catch (_) {
    return tz.UTC;
  }
}

DateTime localDateKey(DateTime utc, String timezone) {
  final loc = locationFor(timezone);
  final local = tz.TZDateTime.from(utc.toUtc(), loc);
  return DateTime(local.year, local.month, local.day);
}

bool sameLocalDay(DateTime a, DateTime b, String timezone) =>
    localDateKey(a, timezone) == localDateKey(b, timezone);

tz.TZDateTime toUserTime(DateTime utc, String timezone) {
  final loc = locationFor(timezone);
  return tz.TZDateTime.from(utc.toUtc(), loc);
}

tz.TZDateTime userNow(String timezone) => toUserTime(DateTime.now().toUtc(), timezone);

DateTime? parseTimeOfDay(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(1970, 1, 1, h, m);
}
