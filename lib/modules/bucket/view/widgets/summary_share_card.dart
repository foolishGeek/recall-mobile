// Recall · branded share card for summary insights. Captured off-screen by
// RecallShare. Editorial lockup: Aura at the top (she wrote it), Recall mark +
// RippleLabs at the foot. Names stay; the composition does the flexing.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../../../core/widgets/recall_mark.dart';
import '../../../../data/models/models.dart';

class SummaryShareCard extends StatelessWidget {
  final String bucketName;
  final SummarizeResult result;
  final RecallColors colors;

  /// Logical width; captured at 3x → ~1140px.
  static const double width = 380;

  const SummaryShareCard({
    super.key,
    required this.bucketName,
    required this.result,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final title = bucketName.trim().isEmpty ? 'Summary' : bucketName.trim();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: RecallShape.xl,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soft top wash — atmosphere without fighting the type.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.cardSunken,
                  c.card,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AuraMark(size: 16, color: c.ink, animate: false),
                    const SizedBox(width: 8),
                    Text(
                      'Summarized by ${AuraBrand.name}',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.1,
                        color: c.grey600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    height: 1.02,
                    letterSpacing: -0.4,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < result.summary.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: c.ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.summary[i],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.5,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (result.keyThemes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: result.keyThemes
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: c.grey300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: c.grey600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Brand foot — follows the theme (light stays light). Hairline top,
          // sunken surface, mark + wordmark left, RippleLabs right.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.cardSunken,
              border: Border(top: BorderSide(color: c.grey200)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: Row(
              children: [
                RecallMark(size: 22, color: c.ink, strokeWidth: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recall',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: 0.2,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Forget forgetting.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          height: 1.1,
                          color: c.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RippleLabs',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: c.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
