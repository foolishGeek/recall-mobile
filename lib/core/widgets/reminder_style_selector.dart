// Recall · ReminderStyleSelector. Account-wide "Cards before a Drop" dial, built
// on ConfigDial. Maps to profiles.drop_frequency. Words-first readout keeps the
// threshold (3 / 5 / 8) visible so users never confuse this with cards-per-session.

import 'package:flutter/material.dart';

import '../utils/drop_readiness.dart';
import '../utils/how_it_works_copy.dart';
import 'config_dial.dart';

class ReminderStyleSelector extends StatelessWidget {
  /// Wire values in reminder order (Gentle → Standard → Persistent).
  static const dbValues = ['weekly', '3xwk', 'daily'];
  static const labels = ['Gentle', 'Standard', 'Persistent'];

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
    final n = dropThresholdFor(wire);
    final readout = wire == kDefaultDropFrequency
        ? 'Default ($n) — waits for $n ready notes'
        : 'Waits for $n ready notes';
    return ConfigDial(
      label: 'Cards before a Drop',
      readout: readout,
      description: 'How many notes must be ready before a Drop is sent.',
      segments: labels,
      activeIndex: i,
      onTap: onTap,
      disabled: disabled,
      howTitle: HowItWorksCopy.reminderStyleTitle,
      howSections: HowItWorksCopy.reminderStyleSections,
      auraPrompt: 'Explain how many cards before a Drop in plain words.',
    );
  }
}
