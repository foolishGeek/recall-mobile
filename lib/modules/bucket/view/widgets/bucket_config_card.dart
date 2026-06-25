import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/soft_card.dart';


class BucketConfigCard extends StatelessWidget {
  final int coolingIndex;
  final int frequencyIndex;
  final bool disabled;
  final ValueChanged<int> onCoolingChanged;
  final ValueChanged<int> onFrequencyChanged;

  const BucketConfigCard({
    super.key,
    required this.coolingIndex,
    required this.frequencyIndex,
    required this.disabled,
    required this.onCoolingChanged,
    required this.onFrequencyChanged,
  });

  static const coolingLabels = ['3d', '7d', '14d', '30d', 'Custom'];
  static const frequencyLabels = ['Weekly', '3×/wk', 'Daily'];

  String get _coolingReadout {
    if (coolingIndex < 0 || coolingIndex >= coolingLabels.length) return '';
    final label = coolingLabels[coolingIndex];
    if (label == 'Custom') return 'Custom';
    return '${label.replaceAll('d', '')} d';
  }

  String get _freqReadout => frequencyLabels[frequencyIndex.clamp(0, 2)];

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: SoftCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(label: 'Cooling period', readout: _coolingReadout),
              const SizedBox(height: 8),
              _Segmented(
                labels: coolingLabels,
                active: coolingIndex,
                onTap: onCoolingChanged,
              ),
              const SizedBox(height: 18),
              _HeaderRow(label: 'Frequency', readout: _freqReadout),
              const SizedBox(height: 8),
              _Segmented(
                labels: frequencyLabels,
                active: frequencyIndex,
                onTap: onFrequencyChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String label;
  final String readout;

  const _HeaderRow({required this.label, required this.readout});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: c.grey500,
            letterSpacing: 0.16 * 10,
          ),
        ),
        Text(
          readout,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int active;
  final ValueChanged<int> onTap;

  const _Segmented({
    required this.labels,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? c.canvas : c.grey300,
        border: isDark ? Border.all(color: c.grey300, width: 1) : null,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final a = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                RecallHaptics.selection();
                onTap(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 32,
                decoration: BoxDecoration(
                  color: a ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: a
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: a ? FontWeight.w600 : FontWeight.w500,
                    color: a ? c.ink : c.grey600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

