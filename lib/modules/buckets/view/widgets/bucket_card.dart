import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
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
    final description = bucket.description?.trim() ?? '';

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
              padding: EdgeInsets.zero,
              sunken: readOnly,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MasteryStrip(progress: mastery, c: c),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Hero(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              if (chip != null) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: chip,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
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
                                nodeCount == 1 ? 'note' : 'notes',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: c.grey500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                height: 1.3,
                                color: c.grey500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _StatusPill(cooling: cooling, c: c),
                        ],
                      ),
                    ),
                  ],
                ),
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

/// The horizontal mastery meter at the top of the card. The fill grows to the
/// mastery fraction; the centred "NN%" is drawn twice so it stays legible on
/// both sides of the fill edge — ink over the track, inkOnInk over the fill.
class _MasteryStrip extends StatelessWidget {
  final double progress; // 0..1
  final RecallColors c;
  const _MasteryStrip({required this.progress, required this.c});

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final label = '${(value * 100).round()}%';
    const height = 30.0;

    final baseStyle = GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1,
    );

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? value : 0.0, end: value),
            duration: reduceMotion ? Duration.zero : RecallMotion.slow,
            curve: RecallMotion.easeOut,
            builder: (context, t, _) {
              final fillWidth = width * t;
              return Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: c.grey200)),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: fillWidth,
                    child: ColoredBox(color: c.ink),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(label, style: baseStyle.copyWith(color: c.ink)),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _LeftClipper(fillWidth),
                      child: Center(
                        child: Text(
                          label,
                          style: baseStyle.copyWith(color: c.inkOnInk),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double width;
  const _LeftClipper(this.width);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.width != width;
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
