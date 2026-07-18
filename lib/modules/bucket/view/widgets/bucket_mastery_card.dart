import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class BucketMasteryCard extends StatelessWidget {
  final double mastery;
  final int dueCount;
  final int overdueCount;

  const BucketMasteryCard({
    super.key,
    required this.mastery,
    this.dueCount = 0,
    this.overdueCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final pct = mastery.clamp(0.0, 100.0);
    final whole = pct.truncate();

    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Cell(
                label: 'Mastery',
                value: '$whole',
                suffix: '%',
                alignment: CrossAxisAlignment.start,
              ),
            ),
            _Divider(color: c.grey200),
            Expanded(
              child: _Cell(
                label: 'Due',
                value: '$dueCount',
                alignment: CrossAxisAlignment.center,
              ),
            ),
            _Divider(color: c.grey200),
            Expanded(
              child: _Cell(
                label: 'Overdue',
                value: '$overdueCount',
                alignment: CrossAxisAlignment.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final CrossAxisAlignment alignment;

  const _Cell({
    required this.label,
    required this.value,
    this.suffix,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MonoLabel(label),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 34,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.7,
                color: c.ink,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  color: c.grey500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: color,
    );
  }
}
