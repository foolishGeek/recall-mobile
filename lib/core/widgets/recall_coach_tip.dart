// Recall · RecallCoachTip. Compact, dismissible one-time explainer strip for
// inline tutorials. Low-cortisol: no modal, no blocking — a calm hint the user
// can read and dismiss. Optional "How it works" opens [showHowItWorksSheet].
// Persist "seen" via LocalStore.markCoachSeen so it shows at most once.
// Motion: gentle fade/slide via RecallMotion; reduced-motion shows instantly.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../utils/recall_haptics.dart';
import 'how_it_works_sheet.dart';

class RecallCoachTip extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onDismiss;

  /// When set with [howItWorksSections], shows a quiet opt-in link.
  final String? howItWorksTitle;
  final List<HowItWorksSection>? howItWorksSections;

  const RecallCoachTip({
    super.key,
    required this.text,
    required this.onDismiss,
    this.icon = Icons.lightbulb_outline_rounded,
    this.howItWorksTitle,
    this.howItWorksSections,
  });

  @override
  State<RecallCoachTip> createState() => _RecallCoachTipState();
}

class _RecallCoachTipState extends State<RecallCoachTip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _hasHowItWorks =>
      widget.howItWorksTitle != null &&
      widget.howItWorksSections != null &&
      widget.howItWorksSections!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final reduce =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    _ctrl = AnimationController(
      vsync: this,
      duration: reduce ? Duration.zero : RecallMotion.normal,
      value: reduce ? 1 : 0,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: RecallMotion.easeOut);
    _slide = Tween<Offset>(
      begin: reduce ? Offset.zero : const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: RecallMotion.easeOut));
    if (!reduce) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openHowItWorks() {
    final title = widget.howItWorksTitle;
    final sections = widget.howItWorksSections;
    if (title == null || sections == null) return;
    showHowItWorksSheet(
      context,
      title: title,
      sections: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.grey200, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(widget.icon, size: 16, color: c.grey500),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.35,
                        color: c.grey600,
                      ),
                    ),
                    if (_hasHowItWorks) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _openHowItWorks,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'How it works',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  RecallHaptics.selection();
                  widget.onDismiss();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 15, color: c.grey500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
