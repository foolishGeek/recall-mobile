import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

/// Sticky footer over a canvas-fade gradient: a compact "Review missed cards"
/// button (hidden when nothing was missed) + the solid "Save & finish" anchor.
class QuizResultsFooter extends StatelessWidget {
  final bool showReviewMissed;
  final bool buildingStack;
  final VoidCallback onReviewMissed;
  final VoidCallback onDone;

  const QuizResultsFooter({
    super.key,
    required this.showReviewMissed,
    required this.buildingStack,
    required this.onReviewMissed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 16 + (bottomPad > 0 ? bottomPad : 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.canvas.withValues(alpha: 0), c.canvas.withValues(alpha: 0.94), c.canvas],
          stops: const [0, 0.36, 0.7],
        ),
      ),
      child: Row(
        children: [
          if (showReviewMissed) ...[
            _ReviewMissedButton(loading: buildingStack, onTap: onReviewMissed),
            const SizedBox(width: 10),
          ],
          Expanded(child: _DoneButton(onTap: onDone)),
        ],
      ),
    );
  }
}

class _ReviewMissedButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _ReviewMissedButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
              )
            : Tooltip(
                message: 'Review missed cards',
                child: Icon(Icons.refresh, size: 20, color: c.ink),
              ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.22),
              offset: const Offset(0, 12),
              blurRadius: 28,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save & finish',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.inkOnInk,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.check, size: 15, color: c.inkOnInk),
          ],
        ),
      ),
    );
  }
}
