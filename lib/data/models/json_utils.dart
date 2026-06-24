// Recall · JSON helpers for models. Null-safe coercion from PostgREST maps plus
// a generic enum parser that falls back to a safe default and leaves a Sentry
// breadcrumb when the server sends a value the app doesn't know (sprint S03 §6).

import 'package:sentry_flutter/sentry_flutter.dart';

/// Parse a wire string into an enum value, falling back to [fallback] (and
/// dropping a breadcrumb) when [raw] is unknown. [wireOf] maps an enum value to
/// its DB string.
T parseEnum<T>(
  List<T> values,
  String Function(T) wireOf,
  Object? raw,
  T fallback,
  String enumName,
) {
  if (raw is String) {
    for (final v in values) {
      if (wireOf(v) == raw) return v;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Unknown $enumName value from server: "$raw"',
        category: 'enum.parse',
        level: SentryLevel.warning,
      ),
    );
  }
  return fallback;
}

/// timestamptz → DateTime (UTC). Returns null for null/blank/unparseable input.
DateTime? asDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toUtc();
}

/// `date` column → DateTime at midnight UTC (date-only semantics).
DateTime? asDate(Object? v) => asDateTime(v);

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double asDouble(Object? v, [double fallback = 0]) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v == 'true' || v == 't' || v == '1';
  if (v is num) return v != 0;
  return fallback;
}

String asString(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String? asStringOrNull(Object? v) => v?.toString();

/// `text[]` / json array → `List<String>` (drops nulls, stringifies entries).
List<String> asStringList(Object? v) {
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  return const [];
}

/// jsonb object → typed map (defensive: returns empty when not an object).
Map<String, dynamic> asJsonMap(Object? v) {
  if (v is Map) {
    return v.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

/// ISO-8601 string for serialization, or null.
String? dateToJson(DateTime? v) => v?.toUtc().toIso8601String();

/// Best-effort parse of a Postgres `interval` text value into a [Duration].
/// PostgREST renders intervals as `HH:MM:SS`, `N days HH:MM:SS`, or ISO-8601
/// (`PT24H`). Returns null when it can't be parsed (the raw string is kept on
/// the model regardless, so nothing is lost).
Duration? parseInterval(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  var rest = raw.trim();
  var total = Duration.zero;

  final dayMatch = RegExp(r'(-?\d+)\s+days?').firstMatch(rest);
  if (dayMatch != null) {
    total += Duration(days: int.parse(dayMatch.group(1)!));
    rest = rest.replaceFirst(dayMatch.group(0)!, '').trim();
  }

  final hms = RegExp(r'(-?\d+):(\d{1,2}):(\d{1,2}(?:\.\d+)?)').firstMatch(rest);
  if (hms != null) {
    total += Duration(
      hours: int.parse(hms.group(1)!),
      minutes: int.parse(hms.group(2)!),
      seconds: double.parse(hms.group(3)!).floor(),
    );
    return total;
  }

  return dayMatch != null ? total : null;
}
