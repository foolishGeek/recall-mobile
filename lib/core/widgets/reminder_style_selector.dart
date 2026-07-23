// Recall · ReminderStyleSelector. Account-wide Drop-nudge dial, built on the
// shared ConfigDial. Reminder style is one setting for the whole app (it maps to
// profiles.drop_frequency), so this is used in Settings — never as a per-bucket
// lever. Words-first readout keeps the effect legible.

import 'package:flutter/material.dart';

import '../utils/how_it_works_copy.dart';
import 'config_dial.dart';

class ReminderStyleSelector extends StatelessWidget {
  /// Wire values in reminder order (Gentle → Standard → Persistent).
  static const dbValues = ['weekly', '3xwk', 'daily'];
  static const labels = ['Gentle', 'Standard', 'Persistent'];
  static const _readouts = [
    'Gentle — waits for a larger set',
    'Standard — a nudge when a set is ready',
    'Persistent — re-nudges until you look',
  ];

  final int activeIndex;
  final ValueChanged<int> onTap;
  final bool disabled;

  const ReminderStyleSelector({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.disabled = false,
  });

  static int indexForDbValue(String v) {
    final i = dbValues.indexOf(v);
    return i < 0 ? 1 : i;
  }

  @override
  Widget build(BuildContext context) {
    final i = activeIndex.clamp(0, labels.length - 1);
    return ConfigDial(
      label: 'Reminder style',
      readout: _readouts[i],
      description: 'How insistently Drops nudge you when notes wait unseen.',
      segments: labels,
      activeIndex: i,
      onTap: onTap,
      disabled: disabled,
      howTitle: HowItWorksCopy.reminderStyleTitle,
      howSections: HowItWorksCopy.reminderStyleSections,
      auraPrompt: 'Explain the reminder styles in plain words.',
    );
  }
}
