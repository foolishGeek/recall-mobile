// Recall · skeleton shimmer. Loading placeholder that breathes opacity 0.4↔1.0
// on a 1400ms loop (Block B1 / design-tokens §5). Never a hard flash; snaps
// static under reduced motion.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../theme/recall_shape.dart';

class RecallSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const RecallSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = RecallShape.md,
  });

  @override
  State<RecallSkeleton> createState() => _RecallSkeletonState();
}

class _RecallSkeletonState extends State<RecallSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RecallMotion.shimmer,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: c.grey300,
        borderRadius: widget.borderRadius,
      ),
    );

    if (reduceMotion) return Opacity(opacity: 0.7, child: box);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: RecallMotion.easeInOut),
      ),
      child: box,
    );
  }
}
