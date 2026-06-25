import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../controller/buckets_controller.dart';

class BucketsFilterRow extends StatelessWidget {
  final BucketFilter current;
  final ValueChanged<BucketFilter> onChanged;

  const BucketsFilterRow({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
      child: Row(
        children: [
          _chip(context, BucketFilter.all, 'All'),
          const SizedBox(width: 7),
          _chip(context, BucketFilter.active, 'Active'),
          const SizedBox(width: 7),
          _chip(context, BucketFilter.cooling, 'Cooling'),
          const SizedBox(width: 7),
          _chip(context, BucketFilter.aToZ, 'A \u2192 Z'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, BucketFilter filter, String label) {
    final c = RecallColors.of(context);
    final active = current == filter;
    return GestureDetector(
      onTap: () => onChanged(filter),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.ink : c.card,
          borderRadius: BorderRadius.circular(14),
          border: active ? null : Border.all(color: c.grey200),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? c.inkOnInk : c.grey600,
          ),
        ),
      ),
    );
  }
}
