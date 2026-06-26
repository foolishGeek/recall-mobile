// Recall · Insights cards. The shared (heatmap) + premium (retention hero,
// mastery rings, weak topics, velocity + Drop-open) surfaces, plus the free
// locked teasers. All data is server-authoritative; these widgets only render.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/utils/insights_heatmap.dart';
import '../../../../core/widgets/heat_dot.dart';
import '../../../../core/widgets/heat_ring.dart';
import '../../../../core/widgets/heatmap.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../core/widgets/retention_curve.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/models.dart';
import '../../../../data/repositories/insights_repository.dart';
import '../../controller/insights_controller.dart';

/// Quiet section header above a card.
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) =>
      MonoLabel(label, padding: const EdgeInsets.only(left: 4, bottom: 10));
}

// ── Activity heatmap (free + premium) ─────────────────────────────────────
class InsightsHeatmapCard extends StatelessWidget {
  final List<List<int>> grid;
  const InsightsHeatmapCard({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final data = grid.isEmpty
        ? List.generate(InsightsHeatmap.weeks, (_) => List.filled(7, 0))
        : grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('ACTIVITY'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Heatmap(data: data),
              const SizedBox(height: 14),
              const HeatmapLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Retention hero + curve (premium) ──────────────────────────────────────
class InsightsRetentionCard extends StatelessWidget {
  final RetentionSimulation retention;
  final bool firstReveal;
  const InsightsRetentionCard({
    super.key,
    required this.retention,
    required this.firstReveal,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('RETENTION'),
        SoftCard(
          elevated: true,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                retention.isProjected
                    ? 'Projected next 90 days'
                    : 'Your retention, next 90 days',
                style: t.headingSm,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroNumeral(
                    value: retention.withRecallPct,
                    label: 'WITH RECALL',
                  ),
                  const SizedBox(width: 26),
                  _HeroNumeral(
                    value: retention.baselinePct,
                    label: 'WITHOUT',
                    muted: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedRetentionCurve(
                points: retention.curvePoints,
                withRecall: (retention.withRecallPct / 100).clamp(0.0, 1.0),
                withoutRecall: (retention.baselinePct / 100).clamp(0.0, 1.0),
                height: 92,
                baselineFirst: firstReveal,
              ),
              const SizedBox(height: 14),
              const _CurveLegend(),
              if (retention.memoriesSaved > 0) ...[
                const SizedBox(height: 14),
                Text(
                  'Recall is protecting ${retention.memoriesSaved} '
                  '${retention.memoriesSaved == 1 ? "memory" : "memories"} from fading.',
                  style: t.bodySm.copyWith(color: c.grey600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroNumeral extends StatelessWidget {
  final double value;
  final String label;
  final bool muted;
  const _HeroNumeral({
    required this.value,
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.round().toString(),
              style: t.numeralLg.copyWith(color: muted ? c.grey500 : c.ink),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('%', style: t.monoCaption.copyWith(color: c.grey500)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: t.monoLabelSm.copyWith(color: c.grey500, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _CurveLegend extends StatelessWidget {
  const _CurveLegend();
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Row(
      children: [
        Container(width: 16, height: 2.5, color: c.ink),
        const SizedBox(width: 6),
        Text('With Recall', style: t.bodyXs.copyWith(color: c.grey600)),
        const SizedBox(width: 18),
        _DashedSwatch(color: c.grey600),
        const SizedBox(width: 6),
        Text('Without', style: t.bodyXs.copyWith(color: c.grey600)),
      ],
    );
  }
}

class _DashedSwatch extends StatelessWidget {
  final Color color;
  const _DashedSwatch({required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(width: 4, height: 2, color: color),
        ),
      ),
    );
  }
}

// ── Mastery rings (premium) ────────────────────────────────────────────────
class InsightsMasteryCard extends StatelessWidget {
  final List<MasteryRing> rings;
  final int bucketCount;
  const InsightsMasteryCard({
    super.key,
    required this.rings,
    required this.bucketCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    if (rings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('MASTERY'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$bucketCount ${bucketCount == 1 ? "bucket" : "buckets"}',
                style: t.bodySm.copyWith(color: c.grey600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final ring in rings)
                    _MasteryRing(ring: ring),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MasteryRing extends StatelessWidget {
  final MasteryRing ring;
  const _MasteryRing({required this.ring});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          AnimatedHeatRing(
            progress: ring.progress,
            heat: ring.heat,
            size: 56,
            center: '${(ring.progress * 100).round()}',
            centerStyle: t.monoNumeral.copyWith(fontSize: 13, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            ring.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.bodyXs.copyWith(color: c.grey600),
          ),
        ],
      ),
    );
  }
}

// ── Weak topics watchlist (premium) ────────────────────────────────────────
class InsightsWeakTopicsCard extends StatelessWidget {
  final List<WeakTopic> topics;
  const InsightsWeakTopicsCard({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    if (topics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('WEAK TOPICS'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Watchlist', style: t.bodySm.copyWith(color: c.grey600)),
              const SizedBox(height: 6),
              for (var i = 0; i < topics.length; i++) ...[
                _WeakRow(topic: topics[i]),
                if (i != topics.length - 1)
                  Divider(height: 1, color: c.grey200),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeakRow extends StatelessWidget {
  final WeakTopic topic;
  const _WeakRow({required this.topic});

  NeoChip get _chip {
    if (topic.difficulty >= 4) return NeoChip.priority(NeoLevel.high);
    if (topic.difficulty == 3) return NeoChip.priority(NeoLevel.medium);
    return NeoChip.priority(NeoLevel.low);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final heat = (1 - (topic.comfort / 5)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          HeatDot(heat: heat),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title.isEmpty ? 'Untitled' : topic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.bucketName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyXs.copyWith(color: c.grey500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _chip,
        ],
      ),
    );
  }
}

// ── Velocity + Drop-open (premium, 2-col) ──────────────────────────────────
class InsightsVelocityDropsRow extends StatelessWidget {
  final double avgVelocity;
  final List<DailyActivity> velocity;
  final NotificationStats? stats;
  final List<NotificationDaily> daily;

  const InsightsVelocityDropsRow({
    super.key,
    required this.avgVelocity,
    required this.velocity,
    required this.stats,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _VelocityCard(avg: avgVelocity, series: velocity),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropOpenCard(stats: stats, daily: daily),
          ),
        ],
      ),
    );
  }
}

class _VelocityCard extends StatelessWidget {
  final double avg;
  final List<DailyActivity> series;
  const _VelocityCard({required this.avg, required this.series});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VELOCITY',
              style: t.monoLabelSm.copyWith(color: c.grey500, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(avg.toStringAsFixed(avg >= 10 ? 0 : 1),
                  style: t.numeralMd.copyWith(fontSize: 26)),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('cards/day',
                    style: t.monoCaption.copyWith(color: c.grey500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: CustomPaint(
              size: const Size(double.infinity, 28),
              painter: _SparklinePainter(
                values: series.map((d) => d.reviewCount.toDouble()).toList(),
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropOpenCard extends StatelessWidget {
  final NotificationStats? stats;
  final List<NotificationDaily> daily;
  const _DropOpenCard({required this.stats, required this.daily});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final rate = stats?.openRate;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DROP OPEN',
              style: t.monoLabelSm.copyWith(color: c.grey500, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                rate == null ? '—' : '${(rate * 100).round()}',
                style: t.numeralMd.copyWith(
                  fontSize: 26,
                  color: rate == null ? c.grey500 : c.ink,
                ),
              ),
              if (rate != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('%',
                      style: t.monoCaption.copyWith(color: c.grey500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: (rate == null || daily.isEmpty)
                ? const SizedBox.shrink()
                : _MiniBars(daily: daily),
          ),
        ],
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  final List<NotificationDaily> daily;
  const _MiniBars({required this.daily});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < daily.length; i++) ...[
          Expanded(
            child: FractionallySizedBox(
              heightFactor: (0.18 + daily[i].openRatio * 0.82).clamp(0.0, 1.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: 0.25 + daily[i].openRatio * 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (i != daily.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final denom = maxV <= 0 ? 1.0 : maxV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / denom) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
