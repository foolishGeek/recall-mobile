// Recall · formats backend `next_drop_time_rpc` for the all-caught-up mono line
// and synced body copy.

import 'package:flutter/material.dart';

import '../../../../core/widgets/mono_label.dart';

class _DropRelative {
  final int dayDiff;
  final String time;

  const _DropRelative({required this.dayDiff, required this.time});
}

_DropRelative? _relativeDrop(DateTime dropAt) {
  final local = dropAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dropDay = DateTime(local.year, local.month, local.day);
  final dayDiff = dropDay.difference(today).inDays;
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return _DropRelative(dayDiff: dayDiff, time: '$h:$m');
}

/// When [dropAt] is null or [hasNotes] is false → fallback copy per S25 §6.
String formatNextDropLine({DateTime? dropAt, required bool hasNotes}) {
  if (!hasNotes || dropAt == null) {
    return 'Add notes to get Drops';
  }

  final rel = _relativeDrop(dropAt)!;
  if (rel.dayDiff <= 0) return 'Next drop · today ${rel.time}';
  if (rel.dayDiff == 1) return 'Next drop · tomorrow ${rel.time}';
  if (rel.dayDiff < 7) {
    return 'Next drop · in ${rel.dayDiff} days · ${rel.time}';
  }
  return 'Next drop · ${rel.time}';
}

/// Body copy for the all-caught-up state — shares the same clock as
/// [formatNextDropLine].
String formatCaughtUpBody({DateTime? dropAt, required bool hasNotes}) {
  const lead = 'No cards due today. ';
  if (!hasNotes || dropAt == null) {
    return '${lead}Add a few notes and Recall will schedule your next drop '
        '— quietly, like always.';
  }

  final rel = _relativeDrop(dropAt)!;
  final String when;
  if (rel.dayDiff <= 0) {
    when = 'today at ${rel.time}';
  } else if (rel.dayDiff == 1) {
    when = 'tomorrow at ${rel.time}';
  } else if (rel.dayDiff < 7) {
    when = 'in ${rel.dayDiff} days at ${rel.time}';
  } else {
    when = 'at ${rel.time}';
  }

  return "${lead}We'll surface your next batch $when — quietly, like always.";
}

class EmptyNextDropLabel extends StatelessWidget {
  final DateTime? dropAt;
  final bool hasNotes;

  const EmptyNextDropLabel({
    super.key,
    required this.dropAt,
    required this.hasNotes,
  });

  @override
  Widget build(BuildContext context) {
    final line = formatNextDropLine(dropAt: dropAt, hasNotes: hasNotes);
    return MonoLabel(line, size: 10, tracking: 0.16);
  }
}
