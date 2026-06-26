// Recall · You memory-simulation hero (premium). One editorial sentence wrapped
// around the dual-line forgetting curve: solid ink "with Recall", dashed grey
// "without". All numbers come from `retention-simulate` (server-authoritative);
// the card only renders + choreographs the reveal. Mount = 360ms fade + 8px
// lift, then the curve draws itself (AnimatedRetentionCurve).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/retention_curve.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/retention_simulation.dart';

class YouHeroCard extends StatelessWidget {
  final RetentionSimulation retention;
  final bool firstReveal;
  const YouHeroCard({
    super.key,
    required this.retention,
    required this.firstReveal,
  });

  bool get _projected => retention.isProjected || retention.reviewDaysCount < 7;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final x = retention.baselinePct.round(); // without Recall
    final y = retention.withRecallPct.round(); // with Recall

    final card = SoftCard(
      elevated: true,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoLabel('Memory simulation', size: 10, tracking: 0.2),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.15,
                letterSpacing: -0.24,
                color: c.ink,
              ),
              children: [
                const TextSpan(text: "Without Recall you'd remember "),
                TextSpan(text: '~$x%', style: TextStyle(color: c.grey500)),
                const TextSpan(text: '. With Recall you remember '),
                TextSpan(text: '$y%', style: TextStyle(color: c.ink)),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              AnimatedRetentionCurve(
                points: retention.curvePoints,
                withRecall: (retention.withRecallPct / 100).clamp(0.0, 1.0),
                withoutRecall: (retention.baselinePct / 100).clamp(0.0, 1.0),
                height: 110,
                baselineFirst: firstReveal,
              ),
              Positioned(
                right: 0,
                top: 14,
                child: Text(
                  '$y%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: -2,
                child: Text(
                  '$x%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: c.grey500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              MonoLabel('Day 0', size: 9.5, tracking: 0.14),
              MonoLabel('90 days', size: 9.5, tracking: 0.14),
            ],
          ),
          if (_projected) ...[
            const SizedBox(height: 10),
            Text(
              'Projected · 7 days of history needed',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                letterSpacing: 9.5 * 0.1,
                color: c.grey500,
              ),
            ),
          ],
        ],
      ),
    );

    return _FadeLiftIn(animate: firstReveal, child: card);
  }
}

/// 360ms fade + 8px lift on first appearance (honors reduced motion).
class _FadeLiftIn extends StatefulWidget {
  final bool animate;
  final Widget child;
  const _FadeLiftIn({required this.animate, required this.child});

  @override
  State<_FadeLiftIn> createState() => _FadeLiftInState();
}

class _FadeLiftInState extends State<_FadeLiftIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!widget.animate || reduceMotion) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: RecallMotion.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
