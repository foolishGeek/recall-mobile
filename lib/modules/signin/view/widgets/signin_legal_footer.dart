// Recall · legal footer. Mono 9.5, grey500, centered: "By continuing you agree
// to our terms and privacy policy." Words "terms" and "privacy policy" tappable.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../controller/signin_controller.dart';

class SigninLegalFooter extends StatelessWidget {
  final SigninController controller;
  const SigninLegalFooter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    final base = GoogleFonts.jetBrainsMono(
      fontSize: 9.5,
      color: c.grey500,
      height: 1.5,
    );
    final tappable = base.copyWith(
      decoration: TextDecoration.none,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
            text: 'terms',
            style: tappable,
            recognizer: TapGestureRecognizer()..onTap = controller.onOpenTerms,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'privacy policy',
            style: tappable,
            recognizer: TapGestureRecognizer()
              ..onTap = controller.onOpenPrivacy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
