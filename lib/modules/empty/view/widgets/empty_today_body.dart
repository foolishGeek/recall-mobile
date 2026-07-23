// Recall · All caught up empty state (docs/13_empty.md §B).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/utils/drop_readiness.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/recall_button.dart';
import '../../../../data/services/metrics_service.dart';
import '../../../settings/controller/settings_controller.dart';
import '../../../settings/view/widgets/settings_pref_sheets.dart';
import '../../../today/view/widgets/today_top_bar.dart';
import 'empty_column_reveal.dart';
import 'empty_done_fast_banner.dart';
import 'empty_moon_illustration.dart';
import 'empty_next_drop_label.dart';

class EmptyTodayBody extends StatelessWidget {
  final int streak;
  final String formattedDate;
  final DateTime? nextDropAt;
  final bool hasNotes;
  final bool pushEnabled;
  final String dropFrequency;
  final DoneFastBanner? doneFastBanner;
  final VoidCallback onOpenQuiz;
  final VoidCallback onAddNote;
  final ValueChanged<String>? onDropFrequencyChanged;

  const EmptyTodayBody({
    super.key,
    required this.streak,
    required this.formattedDate,
    required this.nextDropAt,
    required this.hasNotes,
    required this.onOpenQuiz,
    required this.onAddNote,
    this.pushEnabled = true,
    this.dropFrequency = kDefaultDropFrequency,
    this.doneFastBanner,
    this.onDropFrequencyChanged,
  });

  int get _threshold => dropThresholdFor(dropFrequency);

  bool get _showWarmupHint {
    if (!hasNotes || !pushEnabled || nextDropAt == null) return false;
    return true;
  }

  void _openDropReadiness(BuildContext context) {
    RecallHaptics.selection();
    showFrequencySheet(
      context,
      current: dropFrequency,
      onSelected: (v) {
        if (onDropFrequencyChanged != null) {
          onDropFrequencyChanged!(v);
          return;
        }
        // Fallback when opened from a route that already has Settings wired.
        if (Get.isRegistered<SettingsController>()) {
          Get.find<SettingsController>().setDropFrequency(v);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TodayTopBar(streak: streak, formattedDate: formattedDate),
          Expanded(
            child: Center(
              child: EmptyColumnReveal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (doneFastBanner != null) ...[
                      EmptyDoneFastBanner(banner: doneFastBanner!),
                      const SizedBox(height: 18),
                    ],
                    const EmptyMoonIllustration(height: 140),
                    const SizedBox(height: 28),
                    Text(
                      "You're all caught up. Rest easy.",
                      textAlign: TextAlign.center,
                      style: t.displaySm.copyWith(fontSize: 32, height: 1.12),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        formatCaughtUpBody(
                          dropAt: nextDropAt,
                          hasNotes: hasNotes,
                          pushEnabled: pushEnabled,
                          dropThreshold: _threshold,
                        ),
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _CenterHairline(),
                    const SizedBox(height: 16),
                    EmptyNextDropLabel(
                      dropAt: nextDropAt,
                      hasNotes: hasNotes,
                      pushEnabled: pushEnabled,
                    ),
                    if (_showWarmupHint) ...[
                      const SizedBox(height: 14),
                      _DropWarmupNote(
                        threshold: _threshold,
                        onAdjust: () => _openDropReadiness(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _BottomActions(
            onOpenQuiz: onOpenQuiz,
            onAddNote: onAddNote,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Calm note: the clock ≠ Drop send time. CTA opens Cards-before-a-Drop sheet.
class _DropWarmupNote extends StatelessWidget {
  final int threshold;
  final VoidCallback onAdjust;

  const _DropWarmupNote({
    required this.threshold,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final label = threshold == dropThresholdFor(kDefaultDropFrequency)
        ? 'Default ($threshold)'
        : '$threshold';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAdjust,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.canvas,
          border: Border.all(color: c.grey200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: c.grey500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you don’t see a Drop at that time — that’s normal. '
                    'A Drop waits until $label notes are ready, then nudges you.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.grey600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Change cards before a Drop',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet hairline that closes the rest message before the next-drop mono.
class _CenterHairline extends StatelessWidget {
  const _CenterHairline();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 1,
        color: c.grey300,
      ),
    );
  }
}

/// Bottom strip: quiz (2/3) + add-note (1/3), with the quiz whisper below.
class _BottomActions extends StatelessWidget {
  final VoidCallback onOpenQuiz;
  final VoidCallback onAddNote;

  const _BottomActions({
    required this.onOpenQuiz,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _QuizQuietCta(onPressed: onOpenQuiz),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _AddNoteCta(onPressed: onAddNote),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Quizzes let you revisit topics on your terms — '
          'no due dates, no scores to lose.',
          textAlign: TextAlign.center,
          style: t.bodySm.copyWith(
            color: c.grey500,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Quiet secondary treat — quiz tab mark + brand line.
class _QuizQuietCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuizQuietCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: () {
        RecallHaptics.selection();
        onPressed();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1.5),
          borderRadius: BorderRadius.circular(RecallShape.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/tabs/quiz.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Quiz a quiet corner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact companion CTA — add a note (1/3 of the bottom row).
class _AddNoteCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddNoteCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: () {
        RecallHaptics.selection();
        onPressed();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1.5),
          borderRadius: BorderRadius.circular(RecallShape.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: c.ink),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet nudge when the user has no buckets yet (Today tab guard).
class EmptyTodayNoBucketsBody extends StatelessWidget {
  final int streak;
  final String formattedDate;
  final VoidCallback onMakeBucket;

  const EmptyTodayNoBucketsBody({
    super.key,
    required this.streak,
    required this.formattedDate,
    required this.onMakeBucket,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TodayTopBar(streak: streak, formattedDate: formattedDate),
          Expanded(
            child: Center(
              child: EmptyColumnReveal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start with a bucket',
                      textAlign: TextAlign.center,
                      style: t.headingMd.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Make your first bucket to tuck notes inside — '
                        'Recall will schedule your reviews from there.',
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Make your first bucket',
                      height: 52,
                      onPressed: onMakeBucket,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
