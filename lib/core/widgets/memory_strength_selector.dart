// Recall · MemoryStrengthSelector. Three calm segments for desired retention
// (Relaxed / Balanced / Thorough). NeoChip-adjacent rhythm without color noise —
// monochrome segmented control matching BucketConfigCard. Optional inherit mode
// for per-bucket ("Uses your default") with a quiet clear affordance.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../utils/memory_strength.dart';
import '../utils/recall_haptics.dart';
import 'how_it_works_sheet.dart';
import '../utils/how_it_works_copy.dart';

class MemoryStrengthSelector extends StatelessWidget {
  /// Currently highlighted retention (0..1). For inherit mode, pass the
  /// *effective* value so the segment still shows what scheduling uses.
  final double value;

  /// Called with the chosen preset retention.
  final ValueChanged<double> onChanged;

  /// When true, shows "Uses your default" and an optional clear is hidden
  /// (nothing to clear). When false and [onClear] is set, shows "Custom for
  /// this bucket" + Use default.
  final bool usesDefault;

  /// Clears a per-bucket override (revert to inherited).
  final VoidCallback? onClear;

  final bool disabled;
  final bool showHowItWorks;

  /// Optional bucket scope so the "Ask Aura" explainer footer stays contextual.
  final List<String>? auraBucketIds;

  const MemoryStrengthSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.usesDefault = false,
    this.onClear,
    this.disabled = false,
    this.showHowItWorks = true,
    this.auraBucketIds,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = memoryStrengthPreset(value);
    final reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
                    'MEMORY STRENGTH',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: c.grey500,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                Text(
                  usesDefault
                      ? 'Uses your default'
                      : memoryStrengthLabelFor(value),
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
              'How sure do you want to be when it matters?',
              style: GoogleFonts.inter(fontSize: 12.5, color: c.grey500, height: 1.35),
            ),
            if (showHowItWorks) ...[
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => showHowItWorksSheet(
                  context,
                  title: HowItWorksCopy.memoryStrengthTitle,
                  sections: HowItWorksCopy.memoryStrengthSections,
                  auraPrompt: 'Explain memory strength in plain words.',
                  auraBucketIds: auraBucketIds,
                ),
                behavior: HitTestBehavior.opaque,
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
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? c.canvas : c.grey300,
                border: isDark ? Border.all(color: c.grey300, width: 1) : null,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  for (final p in kMemoryStrengthPresets)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          RecallHaptics.selection();
                          onChanged(p.$1);
                        },
                        child: AnimatedContainer(
                          duration: reduce ? Duration.zero : RecallMotion.fast,
                          curve: RecallMotion.easeOut,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (p.$1 - selected).abs() < 0.001
                                ? c.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: (p.$1 - selected).abs() < 0.001
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
                            p.$2,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: (p.$1 - selected).abs() < 0.001
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: (p.$1 - selected).abs() < 0.001
                                  ? c.ink
                                  : c.grey600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!usesDefault && onClear != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  RecallHaptics.selection();
                  onClear!();
                },
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Use your default',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: c.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
