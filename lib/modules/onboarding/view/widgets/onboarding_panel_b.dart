import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

class OnboardingPanelB extends StatelessWidget {
  const OnboardingPanelB({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/illustrations/onboarding-curve.svg',
            height: 160,
            colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
          ),
          const SizedBox(height: 28),
          Text(
            'Save it once. Revision finds you.',
            textAlign: TextAlign.center,
            style: t.displaySm.copyWith(color: c.ink),
          ),
          const SizedBox(height: 12),
          Text(
            "Drop a topic into Recall and let it go. We resurface each card "
            "right before you'd forget — so it sticks with far less effort.",
            textAlign: TextAlign.center,
            style: t.body.copyWith(color: c.grey600, height: 1.55),
          ),
        ],
      ),
    );
  }
}
