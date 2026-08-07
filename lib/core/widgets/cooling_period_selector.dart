// Recall · CoolingPeriodSelector. Per-bucket "rest the topic" dial, built on the
// shared ConfigDial. Words-first readout ("Rests 14 days") so users learn the
// effect by reading it. Mirrors the existing cooling logic (3d/7d/14d/30d +
// Custom) so saved intervals keep working.

import 'package:flutter/material.dart';

import '../utils/how_it_works_copy.dart';
import 'config_dial.dart';

class CoolingPeriodSelector extends StatelessWidget {
  static const labels = ['3d', '7d', '14d', '30d', 'Custom'];
  static const presetDays = [3, 7, 14, 30];
  static const customIndex = 4;

  final int activeIndex;

  /// Set when [activeIndex] is the Custom slot.
  final int? customDays;
  final ValueChanged<int> onTap;
  final bool disabled;

  /// Optional bucket scope so the "Ask Aura" footer stays contextual.
  final List<String>? auraBucketIds;

  const CoolingPeriodSelector({
    super.key,
    required this.activeIndex,
    this.customDays,
    required this.onTap,
    this.disabled = false,
    this.auraBucketIds,
  });

  /// Plain-English readout of the current cooling choice.
  static String readoutFor(int index, int? customDays) {
    if (index == customIndex) {
      final d = customDays ?? 14;
      return 'Rests $d ${d == 1 ? 'day' : 'days'}';
    }
    if (index < 0 || index >= presetDays.length) return 'Rests 14 days';
    final d = presetDays[index];
    return 'Rests $d days';
  }

  @override
  Widget build(BuildContext context) {
    return ConfigDial(
      label: 'Cooling period',
      readout: readoutFor(activeIndex, customDays),
      description: 'How long the topic rests before it comes back.',
      segments: labels,
      activeIndex: activeIndex,
      onTap: onTap,
      disabled: disabled,
      howTitle: HowItWorksCopy.coolingPeriodTitle,
      howSections: HowItWorksCopy.coolingPeriodSections,
      auraPrompt: 'Explain cooling period in plain, simple words.',
      auraBucketIds: auraBucketIds,
    );
  }
}
