import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../data/models/bucket.dart';
import '../../controller/buckets_controller.dart';
import 'bucket_card.dart';

class BucketsGrid extends StatelessWidget {
  final List<Bucket> buckets;
  final BucketsController controller;
  final AnimationController staggerController;

  const BucketsGrid({
    super.key,
    required this.buckets,
    required this.controller,
    required this.staggerController,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    if (buckets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'NO MATCHES',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: c.grey500,
              letterSpacing: 1.4,
            ),
          ),
        ),
      );
    }

    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    final total = buckets.length;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 178,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          final bucket = buckets[index];
          final card = BucketCard(
            bucket: bucket,
            index: index,
            controller: controller,
            onTap: () => controller.onBucketTap(bucket),
          );

          if (reduceMotion) return card;

          final staggerMs = 60 * index;
          final totalStaggerMs = staggerMs + 320;
          final maxMs = staggerController.duration!.inMilliseconds;
          final begin = (staggerMs / maxMs).clamp(0.0, 1.0);
          final end = (totalStaggerMs / maxMs).clamp(0.0, 1.0);

          final animation = CurvedAnimation(
            parent: staggerController,
            curve: Interval(begin, end, curve: RecallMotion.easeInOut),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (_, child) {
              final v = animation.value;
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - v)),
                  child: child,
                ),
              );
            },
            child: card,
          );
        },
      ),
    );
  }
}
