// Quiet closer-match nudge under a LINKED / WATCH card. Typography-only —
// no card chrome, filled buttons, or badge stickers.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/note_links.dart';
import '../../../../data/models/link_suggestion.dart';

class NodeLinkSuggestionNudge extends StatefulWidget {
  final LinkSuggestion suggestion;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  const NodeLinkSuggestionNudge({
    super.key,
    required this.suggestion,
    required this.onUse,
    required this.onDismiss,
  });

  @override
  State<NodeLinkSuggestionNudge> createState() =>
      _NodeLinkSuggestionNudgeState();
}

class _NodeLinkSuggestionNudgeState extends State<NodeLinkSuggestionNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: RecallMotion.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final label = widget.suggestion.label.trim().isNotEmpty
        ? widget.suggestion.label.trim()
        : urlDomain(widget.suggestion.suggestedUrl);

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'AURA · CLOSER MATCH  ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: c.grey500,
                        letterSpacing: 0.14 * 9.5,
                      ),
                    ),
                    TextSpan(
                      text: label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: c.grey600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            _TextAction(label: 'Use', color: c.ink, onTap: widget.onUse),
            const SizedBox(width: 12),
            _TextAction(
              label: 'Dismiss',
              color: c.grey500,
              onTap: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TextAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
