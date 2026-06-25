import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

class BucketHeader extends StatelessWidget {
  final String name;
  final int nodeCount;
  final String bucketId;

  const BucketHeader({
    super.key,
    required this.name,
    required this.nodeCount,
    required this.bucketId,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel('Bucket · $nodeCount nodes', size: 10.5, tracking: 0.2),
        const SizedBox(height: 6),
        Hero(
          tag: 'bucket_name_$bucketId',
          child: Material(
            color: Colors.transparent,
            child: Text(
              name,
              style: GoogleFonts.fraunces(
                fontSize: 44,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.88,
                color: c.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
