// Recall · ReminderStyleSelector. Account-wide Drop nudge-intensity dial
// (profiles.drop_frequency → drop_intensity). Pattern first; batch size is one
// supporting detail of Gentle / Standard / Persistent / ASAO.

import 'package:flutter/material.dart';

import '../utils/drop_readiness.dart';
import '../utils/how_it_works_copy.dart';
import 'config_dial.dart';

class ReminderStyleSelector extends StatelessWidget {
  /// Wire values in reminder order (Gentle → Standard → Persistent → ASAO).
  static const dbValues = ['weekly', '3xwk', 'daily', 'asap'];
  static const labels = ['Gentle', 'Standard', 'Persistent', 'ASAO'];

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
    final wire = dbValues[i];
    final readout = wire == kDefaultDropFrequency
        ? 'Default · ${dropStyleIntensityLine(wire)}'
        : dropStyleIntensityLine(wire);
    return ConfigDial(
      label: 'Reminder style',
      readout: readout,
      description: 'How insistently Drops nudge you when notes wait unseen.',
      segments: labels,
      activeIndex: i,
      onTap: onTap,
      disabled: disabled,
      howTitle: HowItWorksCopy.reminderStyleTitle,
      howSections: HowItWorksCopy.reminderStyleSections,
      auraPrompt: 'Explain Reminder style in plain words.',
    );
  }
}
