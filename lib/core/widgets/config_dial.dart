// Recall · ConfigDial — the one shared "setting as a legible recipe" control.
// Mono label + right-aligned plain-English readout + one-line effect line +
// optional "How it works" link + a monochrome segmented control. This is the
// pattern MemoryStrengthSelector pioneered, generalized so Cooling / Reminder /
// any future dial look and behave identically app-wide. Color-free by design
// (the design system keeps color only on NeoChip).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../utils/recall_haptics.dart';
import 'how_it_works_sheet.dart';

class ConfigDial extends StatelessWidget {
  /// Mono eyebrow, e.g. 'COOLING PERIOD'.
  final String label;

  /// Right-aligned words-first readout, e.g. 'Rests 14 days'.
  final String readout;

  /// One-line effect description under the label.
  final String description;

  /// Segment labels (monochrome pills).
  final List<String> segments;

  /// Currently active segment index.
  final int activeIndex;
  final ValueChanged<int> onTap;

  final bool disabled;

  // Optional "How it works" explainer.
  final String? howTitle;
  final List<HowItWorksSection>? howSections;
  final String? auraPrompt;
  final List<String>? auraBucketIds;

  const ConfigDial({
    super.key,
    required this.label,
    required this.readout,
    required this.description,
    required this.segments,
    required this.activeIndex,
    required this.onTap,
    this.disabled = false,
    this.howTitle,
    this.howSections,
    this.auraPrompt,
    this.auraBucketIds,
  });

  bool get _hasHow => howTitle != null && howSections != null;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: c.grey500,
                      letterSpacing: 1.6,
                    ),
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
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: c.grey500, height: 1.35),
            ),
            if (_hasHow) ...[
              const SizedBox(height: 2),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showHowItWorksSheet(
                  context,
                  title: howTitle!,
                  sections: howSections!,
                  auraPrompt: auraPrompt,
                  auraBucketIds: auraBucketIds,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'What is it?',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _Segmented(
              labels: segments,
              active: activeIndex,
              onTap: onTap,
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
                duration: reduce ? Duration.zero : RecallMotion.fast,
                curve: RecallMotion.easeOut,
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
                      : const [],
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
