// Recall · You level + XP card. The only round-and-full shape on the screen —
// earned, not gamified. Ring progress / level / XP all derive from server
// truth (profiles.level, profiles.xp) via LevelBand [D-ENG-12]; the title is the
// client constant map [D-UI-4]. Premium = 78px ring + XP/cap readout; free =
// 72px ring, progress bar only.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/level_titles.dart';
import '../../../../core/utils/recall_number.dart';
import '../../../../core/widgets/heat_ring.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class YouLevelCard extends StatelessWidget {
  final LevelBand band;
  final String title;
  final bool premium;

  const YouLevelCard({
    super.key,
    required this.band,
    required this.title,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final ringSize = premium ? 78.0 : 72.0;
    return SoftCard(
      radius: 20,
      padding: premium
          ? const EdgeInsets.fromLTRB(16, 16, 18, 16)
          : const EdgeInsets.all(14),
      child: Row(
        children: [
          AnimatedHeatRing(
            progress: band.progress,
            heat: 0.5, // no halo; flat full-ink ring
            size: ringSize,
            trackWidth: 5,
            ringWidth: 5,
            duration: const Duration(milliseconds: 760),
            center: '${band.level}',
            centerStyle: GoogleFonts.fraunces(
              fontSize: premium ? 30 : 24,
              fontWeight: FontWeight.w500,
              color: c.ink,
            ),
          ),
          SizedBox(width: premium ? 18 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel('Level ${band.level} · $title',
                    size: 9.5, tracking: 0.18),
                const SizedBox(height: 4),
                Text(
                  '${RecallNumber.grouped(band.xpToNext)} XP to Level ${band.nextLevel}',
                  style: GoogleFonts.fraunces(
                    fontSize: premium ? 18 : 20,
                    fontWeight: FontWeight.w500,
                    height: premium ? 1.2 : 1.15,
                    letterSpacing: -0.18,
                    color: c.ink,
                  ),
                ),
                SizedBox(height: premium ? 10 : 8),
                _ProgressBar(progress: band.progress),
                if (premium) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${RecallNumber.grouped(band.xp)} XP',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5, color: c.grey500),
                      ),
                      Text(
                        RecallNumber.grouped(band.cap),
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5, color: c.grey500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: c.grey300),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
