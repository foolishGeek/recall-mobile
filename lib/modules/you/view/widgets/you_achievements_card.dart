// Recall · You achievements (premium). Solid-ink tiles for earned, dashed-grey
// for locked. No glitter, no confetti — completion is the reward. A badge
// earned since the last visit springs in (RecallMotion.bubbly, 0.6→1.0). The
// catalog is the 12-row canonical seed [D-SCHEMA-1]; counts are server truth.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/models.dart';
import '../../controller/you_controller.dart';

/// Calm line-icon per achievement slug (ink on the earned tiles).
const Map<String, IconData> _kSlugIcon = {
  'first_review': Icons.check_circle_outline,
  'streak_3': Icons.local_fire_department_outlined,
  'streak_7': Icons.local_fire_department,
  'streak_30': Icons.calendar_today_outlined,
  'streak_100': Icons.emoji_events_outlined,
  'stack_complete': Icons.layers_outlined,
  'stacks_10': Icons.layers,
  'bucket_master': Icons.workspace_premium_outlined,
  'memories_10': Icons.bookmark_outline,
  'memories_50': Icons.bookmarks_outlined,
  'quiz_ace': Icons.psychology_outlined,
  'night_owl': Icons.bedtime_outlined,
};

class YouAchievementsCard extends StatelessWidget {
  final List<Achievement> earned;
  final int unlockedCount;
  final Set<String> newlyUnlocked;

  const YouAchievementsCard({
    super.key,
    required this.earned,
    required this.unlockedCount,
    required this.newlyUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedCount of $kAchievementTotal',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: c.grey500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: _slots()),
        ],
      ),
    );
  }

  /// Exactly four columns: earned tiles (most recent first), then one aggregate
  /// "+N more" locked tile, padded with quiet placeholders to keep the rhythm.
  List<Widget> _slots() {
    final showEarned = earned.take(unlockedCount >= kAchievementTotal ? 4 : 3);
    final tiles = <Widget>[
      for (final a in showEarned)
        _BadgeTile.earned(
          icon: _kSlugIcon[a.slug] ?? Icons.star_outline,
          label: a.title,
          isNew: newlyUnlocked.contains(a.id),
        ),
    ];

    final remaining = kAchievementTotal - unlockedCount;
    if (remaining > 0) {
      tiles.add(_BadgeTile.aggregate(label: '$remaining more'));
    }
    while (tiles.length < 4) {
      tiles.add(const _BadgeTile.placeholder());
    }

    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(Expanded(child: tiles[i]));
      if (i != tiles.length - 1) out.add(const SizedBox(width: 14));
    }
    return out;
  }
}

enum _BadgeKind { earned, aggregate, placeholder }

class _BadgeTile extends StatelessWidget {
  final _BadgeKind kind;
  final IconData? icon;
  final String label;
  final bool isNew;

  const _BadgeTile.earned({
    required this.icon,
    required this.label,
    required this.isNew,
  }) : kind = _BadgeKind.earned;

  const _BadgeTile.aggregate({required this.label})
      : kind = _BadgeKind.aggregate,
        icon = Icons.lock_outline,
        isNew = false;

  const _BadgeTile.placeholder()
      : kind = _BadgeKind.placeholder,
        icon = null,
        label = '',
        isNew = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final earned = kind == _BadgeKind.earned;

    Widget tile = SizedBox(
      width: 46,
      height: 46,
      child: earned
          ? Container(
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: c.inkOnInk),
            )
          : CustomPaint(
              painter: _DashedTileBorder(color: c.grey400),
              child: Center(
                child: icon == null
                    ? const SizedBox.shrink()
                    : Icon(icon, size: 18, color: c.grey400),
              ),
            ),
    );

    if (earned && isNew) tile = _SpringIn(child: tile);

    return Column(
      children: [
        tile,
        const SizedBox(height: 5),
        SizedBox(
          height: 12,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.9,
              color: earned ? c.grey600 : c.grey400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Scale 0.6 → 1.0 with the calm bubbly overshoot (honors reduced motion).
class _SpringIn extends StatelessWidget {
  final Widget child;
  const _SpringIn({required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: RecallMotion.bubbly,
      builder: (context, value, c) => Transform.scale(scale: value, child: c),
      child: child,
    );
  }
}

class _DashedTileBorder extends CustomPainter {
  final Color color;
  _DashedTileBorder({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, (dist + dash).clamp(0, metric.length)),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTileBorder old) => old.color != color;
}
