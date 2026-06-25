import 'package:flutter/material.dart';

import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../data/models/due_preview_node.dart';
import 'today_peeking_card.dart';

class TodayPeekingStack extends StatelessWidget {
  final List<DuePreviewNode> nodes;
  final Animation<double> animation;

  const TodayPeekingStack({
    super.key,
    required this.nodes,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final count = nodes.length.clamp(0, 3);
    if (count == 0) return const SizedBox(height: 236);

    return SizedBox(
      height: 236,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          // Draw back-to-front so the hero (nodes[0], the hottest) sits at the
          // bottom on top of the z-order, with cooler cards peeking above it.
          final children = <Widget>[];
          for (int i = count - 1; i >= 0; i--) {
            final isFront = i == 0;
            final restTop =
                isFront ? (count - 1) * 42.0 : (count - 1 - i) * 42.0;
            final restInset = i * 11.0;

            // Entrance: every card starts collapsed near the hero (as if deep in
            // the deck) then fans up to its resting slot. Back cards travel the
            // furthest so the whole stack reads as "coming from far away".
            final start = (i * 0.12).clamp(0.0, 0.6);
            const span = 0.7;
            final t = Interval(start, (start + span).clamp(0.0, 1.0),
                    curve: RecallMotion.bubbly)
                .transform(animation.value);
            // bubbly overshoots past 1.0 → cards spring slightly above their slot
            // then settle: the slow bounce on load.
            final riseFrom = i * 42.0 + 26.0;
            final translateY = riseFrom * (1 - t);
            final scale = 0.84 + 0.16 * t;
            final opacity = Interval(start, start + 0.22, curve: Curves.easeOut)
                .transform(animation.value)
                .clamp(0.0, 1.0);

            children.add(Positioned(
              top: restTop,
              left: restInset,
              right: restInset,
              bottom: isFront ? 0 : null,
              height: isFront ? null : 62,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: TodayPeekingCard(
                      node: nodes[i],
                      index: i,
                      total: count,
                      onTap: () => RecallHaptics.selection(),
                    ),
                  ),
                ),
              ),
            ));
          }
          return Stack(clipBehavior: Clip.none, children: children);
        },
      ),
    );
  }
}
