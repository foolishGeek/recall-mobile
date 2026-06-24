// Recall · sign-in lockup. RecallMark + Nunito wordmark + Instrument Serif
// tagline, centered. Fades in 380ms on first frame.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/recall_mark.dart';

class SigninLockup extends StatefulWidget {
  const SigninLockup({super.key});

  @override
  State<SigninLockup> createState() => _SigninLockupState();
}

class _SigninLockupState extends State<SigninLockup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RecallMark(size: 58, color: c.ink),
          const SizedBox(height: 26),
          Text(
            'Recall',
            style: GoogleFonts.nunito(
              fontSize: 54,
              fontWeight: FontWeight.w700,
              color: c.ink,
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Forget forgetting.',
            style: t.serifItalic.copyWith(fontSize: 30),
          ),
        ],
      ),
    );
  }
}
