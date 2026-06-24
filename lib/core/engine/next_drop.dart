// Recall · getNextDropTime — deterministic next-drop label time [D-ENG-5].

import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/bucket.dart';
import '../../../data/models/profile.dart';
import 'params/engine_config.dart';
import 'utils/timezone_utils.dart';

DateTime getNextDropTime(
  Profile p, {
  Bucket? bucket,
  DateTime? now,
  EngineConfig config = EngineConfig.defaults,
  int sentDropsLast7Days = 0,
  bool allBucketsInCooldown = false,
  DateTime? minCooldownUntil,
}) {
  final utcNow = (now ?? DateTime.now()).toUtc();
  var t = _nextFifteenMinuteTick(utcNow, p.timezone);

  t = _applyQuietHours(t, p, p.timezone);

  final budget = config.dropBudgetForFrequency(p.dropFrequency);
  if (sentDropsLast7Days >= budget) {
    t = _advanceToNextPeriod(t, p.dropFrequency, p.timezone);
  }

  if (allBucketsInCooldown && minCooldownUntil != null) {
    final cooldownUtc = minCooldownUntil.toUtc();
    if (cooldownUtc.isAfter(t)) t = cooldownUtc;
  } else if (bucket?.cooldownUntil != null) {
    final bucketCooldown = bucket!.cooldownUntil!.toUtc();
    if (bucketCooldown.isAfter(t)) t = bucketCooldown;
  }

  return t.toUtc();
}

DateTime _nextFifteenMinuteTick(DateTime utcNow, String timezone) {
  final local = toUserTime(utcNow, timezone);
  final minute = ((local.minute / 15).ceil() * 15) % 60;
  var hour = local.hour;
  if (local.minute % 15 != 0 || local.second > 0 || local.millisecond > 0) {
    if (minute == 0) hour += 1;
  }
  var candidate = tz.TZDateTime(
    local.location,
    local.year,
    local.month,
    local.day,
    hour,
    minute,
  );
  if (!candidate.isAfter(local)) {
    candidate = candidate.add(const Duration(minutes: 15));
  }
  return candidate.toUtc();
}

DateTime _applyQuietHours(DateTime tUtc, Profile p, String timezone) {
  final start = parseTimeOfDay(p.quietHoursStart);
  final end = parseTimeOfDay(p.quietHoursEnd);
  if (start == null || end == null) return tUtc;

  final local = toUserTime(tUtc, timezone);
  final startMin = start.hour * 60 + start.minute;
  final endMin = end.hour * 60 + end.minute;
  final currentMin = local.hour * 60 + local.minute;

  final inQuiet = startMin <= endMin
      ? currentMin >= startMin && currentMin < endMin
      : currentMin >= startMin || currentMin < endMin;

  if (!inQuiet) return tUtc;

  final endLocal = tz.TZDateTime(
    local.location,
    local.year,
    local.month,
    local.day,
    end.hour,
    end.minute,
  );
  final adjusted = currentMin >= startMin && startMin > endMin
      ? endLocal.add(const Duration(days: 1))
      : endLocal;
  return adjusted.toUtc();
}

DateTime _advanceToNextPeriod(
  DateTime tUtc,
  String frequency,
  String timezone,
) {
  final local = toUserTime(tUtc, timezone);
  switch (frequency) {
    case 'weekly':
      return tz.TZDateTime(local.location, local.year, local.month, local.day)
          .add(const Duration(days: 7))
          .toUtc();
    case '3xwk':
      return local.add(const Duration(days: 3)).toUtc();
    default:
      return tz.TZDateTime(
        local.location,
        local.year,
        local.month,
        local.day,
      ).add(const Duration(days: 1)).toUtc();
  }
}
