// Recall · ProgressDots & ProgressBarThin — used in Review and Quiz.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

class ProgressDots extends StatelessWidget {
  final int total;
  final int done; // fully done
  final int current; // 1-indexed; -1 to disable
  const ProgressDots({
    super.key,
    required this.total,
    required this.done,
    this.current = -1,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        Color color;
        if (i < done) {
          color = c.ink;
        } else if (i + 1 == current) {
          color = c.grey600.withValues(alpha: 0.6);
        } else {
          color = c.grey400;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class ProgressBarThin extends StatelessWidget {
  final double progress; // 0..1
  final double height;
  const ProgressBarThin({super.key, required this.progress, this.height = 2});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(color: c.grey200),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: c.ink),
        ),
      ),
    );
  }
}
