import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../data/models/models.dart';

class BucketSelectorSheet extends StatelessWidget {
  final List<Bucket> buckets;
  final Bucket? selected;
  final ValueChanged<Bucket> onSelected;
  final ValueChanged<String>? onCreateBucket;

  const BucketSelectorSheet({
    super.key,
    required this.buckets,
    this.selected,
    required this.onSelected,
    this.onCreateBucket,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Bucket> buckets,
    Bucket? selected,
    required ValueChanged<Bucket> onSelected,
    ValueChanged<String>? onCreateBucket,
  }) {
    final c = RecallColors.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BucketSelectorSheet(
        buckets: buckets,
        selected: selected,
        onSelected: onSelected,
        onCreateBucket: onCreateBucket,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final isEmpty = buckets.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Illustration
            SvgPicture.asset(
              isEmpty
                  ? 'assets/illustrations/empty-seed-in-bowl.svg'
                  : 'assets/illustrations/onboarding-buckets.svg',
              height: isEmpty ? 72 : 56,
              colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              isEmpty ? 'Nothing planted yet.' : 'Pick a bucket',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              isEmpty
                  ? 'Create your first bucket to get started.'
                  : 'Where should this node live?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Bucket list (only when non-empty)
            if (!isEmpty) ...[
              ...buckets.map((bucket) {
                final isSelected = bucket.id == selected?.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _BucketTile(
                    bucket: bucket,
                    isSelected: isSelected,
                    colors: c,
                    onTap: () {
                      RecallHaptics.selection();
                      onSelected(bucket);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // New bucket row
            if (onCreateBucket != null)
              _NewBucketRow(
                colors: c,
                onTap: () {
                  RecallHaptics.light();
                  Navigator.pop(context);
                  _showCreateDialog(context, c);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, RecallColors c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'New bucket',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: c.ink,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15, color: c.ink),
          decoration: InputDecoration(
            hintText: 'Bucket name',
            hintStyle: GoogleFonts.inter(fontSize: 15, color: c.grey400),
            filled: true,
            fillColor: c.canvas,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.ink, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: c.grey600, fontSize: 14)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                onCreateBucket?.call(name);
              }
            },
            child: Text('Create',
                style: GoogleFonts.inter(
                    color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  final Bucket bucket;
  final bool isSelected;
  final RecallColors colors;
  final VoidCallback onTap;

  const _BucketTile({
    required this.bucket,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.cardSunken : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.ink.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bucket.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 20, color: colors.ink),
          ],
        ),
      ),
    );
  }
}

class _NewBucketRow extends StatelessWidget {
  final RecallColors colors;
  final VoidCallback onTap;

  const _NewBucketRow({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colors.grey300,
          borderRadius: 12,
          dashWidth: 5,
          dashGap: 4,
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: colors.grey500),
              const SizedBox(width: 10),
              Text(
                'New bucket',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(
          metric.extractPath(distance, end),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      color != old.color || borderRadius != old.borderRadius;
}
