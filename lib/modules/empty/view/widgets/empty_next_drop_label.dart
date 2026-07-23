// Recall · formats backend `next_drop_time_rpc` for the all-caught-up mono line
// and synced body copy. The time is when the *next cards warm up* — Reminder
// style (nudge intensity) decides when a Drop is actually sent.

import 'package:flutter/material.dart';

import '../../../../core/utils/drop_readiness.dart';
import '../../../../core/utils/recall_time.dart';
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
  return _DropRelative(dayDiff: dayDiff, time: RecallTime.clock12h(local));
}

/// The honest reason we can (or can't) show a next-drop time. Distinct states
/// so the UI never promises a Drop that can't happen — the backend
/// `next_drop_time_rpc` already returns NULL for the impossible cases; the
/// client just needs to explain *why* calmly.
enum NextDropState { scheduled, noNotes, remindersOff, warming }

NextDropState _dropState({
  required DateTime? dropAt,
  required bool hasNotes,
  required bool pushEnabled,
}) {
  if (!hasNotes) return NextDropState.noNotes;
  if (!pushEnabled) return NextDropState.remindersOff;
  if (dropAt == null) return NextDropState.warming;
  return NextDropState.scheduled;
}

/// Mono micro-line under the caught-up illustration. Honest per state; only the
/// `scheduled` state shows a real time (when the next cards warm up).
String formatNextDropLine({
  DateTime? dropAt,
  required bool hasNotes,
  bool pushEnabled = true,
}) {
  switch (_dropState(dropAt: dropAt, hasNotes: hasNotes, pushEnabled: pushEnabled)) {
    case NextDropState.noNotes:
      return 'Add notes to get Drops';
    case NextDropState.remindersOff:
      return 'Reminders off';
    case NextDropState.warming:
      return 'Preparing your next drop';
    case NextDropState.scheduled:
      final rel = _relativeDrop(dropAt!)!;
      if (rel.dayDiff <= 0) {
        return 'Next cards ready · today ${rel.time}';
      }
      if (rel.dayDiff == 1) {
        return 'Next cards ready · tomorrow ${rel.time}';
      }
      if (rel.dayDiff < 7) {
        return 'Next cards ready · in ${rel.dayDiff} days · ${rel.time}';
      }
      return 'Next cards ready · ${rel.time}';
  }
}

/// Body copy for the all-caught-up state — shares the same clock + states as
/// [formatNextDropLine].
String formatCaughtUpBody({
  DateTime? dropAt,
  required bool hasNotes,
  bool pushEnabled = true,
  String dropFrequency = kDefaultDropFrequency,
}) {
  const lead = 'No cards due today. ';
  switch (_dropState(dropAt: dropAt, hasNotes: hasNotes, pushEnabled: pushEnabled)) {
    case NextDropState.noNotes:
      return '${lead}Add a few notes and Recall will schedule your next drop '
          '— quietly, like always.';
    case NextDropState.remindersOff:
      return "${lead}Turn on reminders and we'll nudge you the moment your "
          'next batch is ready — quietly, like always.';
    case NextDropState.warming:
      return "${lead}Recall is lining up your next drop — we'll nudge you "
          "quietly the moment it's ready.";
    case NextDropState.scheduled:
      final rel = _relativeDrop(dropAt!)!;
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
      final style = dropStyleName(dropFrequency);
      final isDefault = dropFrequency == kDefaultDropFrequency;
      final styleBit = isDefault ? '$style (Default)' : style;
      return '${lead}The next notes warm up $when. Your Reminder style '
          '($styleBit) decides when a Drop is actually sent — not necessarily '
          'at that exact minute.';
  }
}

class EmptyNextDropLabel extends StatelessWidget {
  final DateTime? dropAt;
  final bool hasNotes;
  final bool pushEnabled;

  const EmptyNextDropLabel({
    super.key,
    required this.dropAt,
    required this.hasNotes,
    this.pushEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final line = formatNextDropLine(
      dropAt: dropAt,
      hasNotes: hasNotes,
      pushEnabled: pushEnabled,
    );
    return MonoLabel(line, size: 10, tracking: 0.16);
  }
}
