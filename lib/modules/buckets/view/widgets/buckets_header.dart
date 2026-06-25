import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class BucketsHeader extends StatelessWidget {
  final int bucketCount;
  final int nodeCount;

  const BucketsHeader({
    super.key,
    required this.bucketCount,
    required this.nodeCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buckets',
            style: GoogleFonts.fraunces(
              fontSize: 42,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.84,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$bucketCount buckets',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: c.grey600,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '\u00B7',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: c.grey400,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$nodeCount nodes',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: c.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
