import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/heat_summary.dart';
import 'bucket_heat_bar.dart';

class BucketMasteryCard extends StatelessWidget {
  final double mastery;
  final HeatSummary heat;

  const BucketMasteryCard({
    super.key,
    required this.mastery,
    required this.heat,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final pct = mastery.clamp(0.0, 100.0);
    final whole = pct.truncate();

    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoLabel('Mastery'),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$whole',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.7,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        '%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          color: c.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const MonoLabel('Hot · warm · cool'),
                  const SizedBox(height: 4),
                  Text(
                    '${heat.hotCount} · ${heat.warmCount} · ${heat.coolCount}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      color: c.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          BucketHeatBar(segments: heat.segments),
        ],
      ),
    );
  }
}
