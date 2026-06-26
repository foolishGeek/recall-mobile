// Recall · formats backend `next_drop_time_rpc` for the all-caught-up mono line.

import 'package:flutter/material.dart';

import '../../../../core/widgets/mono_label.dart';

/// When [dropAt] is null or [hasNotes] is false → fallback copy per S25 §6.
String formatNextDropLine({DateTime? dropAt, required bool hasNotes}) {
  if (!hasNotes || dropAt == null) {
    return 'Add notes to get Drops';
  }

  final local = dropAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dropDay = DateTime(local.year, local.month, local.day);
  final dayDiff = dropDay.difference(today).inDays;
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  final time = '$h:$m';

  if (dayDiff <= 0) return 'Next drop · today $time';
  if (dayDiff == 1) return 'Next drop · tomorrow $time';
  if (dayDiff < 7) return 'Next drop · in $dayDiff days · $time';
  return 'Next drop · $time';
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
