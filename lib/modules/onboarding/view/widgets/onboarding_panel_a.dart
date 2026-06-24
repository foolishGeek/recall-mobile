import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/recall_mark.dart';

class OnboardingPanelA extends StatelessWidget {
  const OnboardingPanelA({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RecallMark(size: 62, color: c.ink),
          const SizedBox(height: 24),
          Text(
            'Recall',
            style: GoogleFonts.nunito(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: c.ink,
              letterSpacing: 0.22,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Forget forgetting.',
            style: t.serifItalic.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
