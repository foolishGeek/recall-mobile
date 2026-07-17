import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/heat_ring.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/bucket.dart';
import '../../controller/buckets_controller.dart';

class BucketCard extends StatelessWidget {
  final Bucket bucket;
  final int index;
  final BucketsController controller;
  final VoidCallback onTap;

  const BucketCard({
    super.key,
    required this.bucket,
    required this.index,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final readOnly = controller.isReadOnly(bucket);
    final cooling = controller.isCooling(bucket);
    final mastery = controller.masteryFor(bucket);
    final nodeCount = controller.nodeCountFor(bucket);
    final dominant = controller.dominantPriorityFor(bucket);
    final dropValue = controller.nextDropValue(bucket);

    NeoChip? chip;
    if (dominant >= 4) {
      chip = NeoChip.priority(NeoLevel.high);
    } else if (dominant == 3) {
      chip = NeoChip.priority(NeoLevel.medium);
    }

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: readOnly ? 0.5 : 1.0,
        child: Stack(
          children: [
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.all(16),
              sunken: readOnly,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'progress_ring_${bucket.id}',
                        child: HeatRing(
                          progress: mastery,
                          heat: 0.55,
                          size: 44,
                          trackWidth: 3,
                          ringWidth: 3.5,
                        ),
                      ),
                      const Spacer(),
                      if (chip != null) chip,
                    ],
                  ),
                  const SizedBox(height: 14),
                  Hero(
                    tag: 'bucket_name_${bucket.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        bucket.name,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          letterSpacing: -0.2,
                          color: c.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$nodeCount',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: c.grey600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'nodes',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: c.grey500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT DROP',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                color: c.grey500,
                                letterSpacing: 0.16 * 8.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dropValue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                color: cooling ? c.grey500 : c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(cooling: cooling, c: c),
                    ],
                  ),
                ],
              ),
            ),
            if (readOnly)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.lock_outline, size: 14, color: c.grey500),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool cooling;
  final RecallColors c;
  const _StatusPill({required this.cooling, required this.c});

  @override
  Widget build(BuildContext context) {
    // Active = filled ink dot on paper; Cooling = grey dot, hollow pill.
    final dotColor = cooling ? c.grey500 : c.ink;
    final textColor = cooling ? c.grey500 : c.ink;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: cooling ? Colors.transparent : c.canvas,
        border: Border.all(color: c.grey400),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            cooling ? 'Cooling' : 'Active',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: cooling ? FontWeight.w500 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
