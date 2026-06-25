import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class BucketConfigCard extends StatelessWidget {
  final int coolingIndex;
  final int frequencyIndex;
  final int capIndex;
  final bool disabled;
  final ValueChanged<int> onCoolingChanged;
  final ValueChanged<int> onFrequencyChanged;
  final ValueChanged<int> onCapChanged;

  const BucketConfigCard({
    super.key,
    required this.coolingIndex,
    required this.frequencyIndex,
    required this.capIndex,
    required this.disabled,
    required this.onCoolingChanged,
    required this.onFrequencyChanged,
    required this.onCapChanged,
  });

  static const _coolingLabels = ['14d', '30d', '60d'];
  static const _freqLabels = ['Daily', '3×/wk', 'Weekly'];
  static const _capLabels = ['5', '10', '15', '20', '30'];

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonoLabel('Cooling period'),
              const SizedBox(height: 8),
              _Segmented(
                labels: _coolingLabels,
                active: coolingIndex,
                onTap: onCoolingChanged,
              ),
              const SizedBox(height: 14),
              const MonoLabel('Frequency'),
              const SizedBox(height: 8),
              _Segmented(
                labels: _freqLabels,
                active: frequencyIndex,
                onTap: onFrequencyChanged,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const MonoLabel('Daily cap'),
                  const Spacer(),
                  Text(
                    _capLabels[capIndex],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _TickSlider(
                count: _capLabels.length,
                active: capIndex,
                onTap: onCapChanged,
              ),
            ],
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.grey300,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final a = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 32,
                decoration: BoxDecoration(
                  color: a ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
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
                    fontSize: 12.5,
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

class _TickSlider extends StatelessWidget {
  final int count;
  final int active;
  final ValueChanged<int> onTap;

  const _TickSlider({
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 1, color: c.grey300),
          Row(
            children: List.generate(count, (i) {
              final a = i == active;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: a ? 14 : 8,
                      height: a ? 14 : 8,
                      decoration: BoxDecoration(
                        color: a ? c.ink : c.grey400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
