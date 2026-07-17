// Recall · Insights locked premium teasers (free / downgraded). A sunken card
// with a PRO badge, a dimmed personalized preview, and shame-free copy that
// hints at the value behind the paywall. Tapping routes to /paywall. These are
// the conversion surfaces — calm, never nagging (low-cortisol is the moat).

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/heat_ring.dart';
import '../../../../core/widgets/retention_curve.dart';
import '../../../../core/widgets/soft_card.dart';
import 'insights_chrome.dart';

class InsightsLockedBlock extends StatelessWidget {
  final String title;
  final String body;
  final Widget preview;
  final String? teaser;
  final VoidCallback onTap;

  const InsightsLockedBlock({
    super.key,
    required this.title,
    required this.body,
    required this.preview,
    required this.onTap,
    this.teaser,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SoftCard(
        sunken: true,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: t.headingSm)),
                const InsightsSolidBadge(label: 'PRO'),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: t.bodySm.copyWith(color: c.grey600)),
            const SizedBox(height: 16),
            // Dimmed preview — a glimpse of the real thing.
            Opacity(opacity: 0.42, child: preview),
            if (teaser != null) ...[
              const SizedBox(height: 16),
              Text(teaser!, style: t.bodySm.copyWith(color: c.grey600)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ghost forgetting-curve preview using cached `profiles.retention_*` when
/// present (personalized), else gentle defaults.
class LockedCurvePreview extends StatelessWidget {
  final double? cachedWithRecall;
  final double? cachedBaseline;
  const LockedCurvePreview({
    super.key,
    this.cachedWithRecall,
    this.cachedBaseline,
  });

  @override
  Widget build(BuildContext context) {
    return RetentionCurve(
      withRecall: ((cachedWithRecall ?? 82) / 100).clamp(0.0, 1.0),
      withoutRecall: ((cachedBaseline ?? 42) / 100).clamp(0.0, 1.0),
      height: 80,
    );
  }
}

/// Ghost mastery rings preview for the second locked teaser.
class LockedMasteryPreview extends StatelessWidget {
  const LockedMasteryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        HeatRing(progress: 0.72, heat: 0.55, size: 48, trackWidth: 3, ringWidth: 3.5),
        HeatRing(progress: 0.54, heat: 0.55, size: 48, trackWidth: 3, ringWidth: 3.5),
        HeatRing(progress: 0.86, heat: 0.55, size: 48, trackWidth: 3, ringWidth: 3.5),
        HeatRing(progress: 0.41, heat: 0.55, size: 48, trackWidth: 3, ringWidth: 3.5),
      ],
    );
  }
}
