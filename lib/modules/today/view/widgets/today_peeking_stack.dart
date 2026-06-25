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
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: List.generate(count, (i) {
            final staggerStart = i * (80 / 560);
            final staggerEnd = staggerStart + (320 / 560);
            final t = Interval(
              staggerStart.clamp(0.0, 1.0),
              staggerEnd.clamp(0.0, 1.0),
              curve: RecallMotion.easeOut,
            ).transform(animation.value);

            final opacity = t;
            final translateY = 6.0 * (1 - t);

            return Positioned(
              top: _topFor(i),
              left: _leftFor(i),
              right: _rightFor(i),
              bottom: i == count - 1 ? 0 : null,
              height: i == count - 1 ? null : 62,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: TodayPeekingCard(
                    node: nodes[i],
                    index: i,
                    onTap: () => RecallHaptics.selection(),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  double _topFor(int i) {
    switch (i) {
      case 0:
        return 0;
      case 1:
        return 42;
      default:
        return 84;
    }
  }

  double _leftFor(int i) {
    switch (i) {
      case 0:
        return 22;
      case 1:
        return 11;
      default:
        return 0;
    }
  }

  double _rightFor(int i) => _leftFor(i);
}
