import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_shape.dart';

class BucketsSearchField extends StatelessWidget {
  final bool visible;
  final ValueChanged<String> onChanged;

  const BucketsSearchField({
    super.key,
    required this.visible,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return AnimatedSize(
      duration: RecallMotion.normal,
      curve: RecallMotion.easeOut,
      child: visible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: TextField(
                onChanged: onChanged,
                style: GoogleFonts.inter(fontSize: 14, color: c.ink),
                decoration: InputDecoration(
                  hintText: 'Search buckets\u2026',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: c.grey500),
                  filled: true,
                  fillColor: c.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RecallShape.radiusSm),
                    borderSide: BorderSide(color: c.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RecallShape.radiusSm),
                    borderSide: BorderSide(color: c.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RecallShape.radiusSm),
                    borderSide: BorderSide(color: c.grey400),
                  ),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.grey500),
                  isDense: true,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
