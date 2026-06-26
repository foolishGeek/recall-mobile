// Review suggestion — a calm, git-style read-only diff of Aura's rewrite of the
// note body. Removed lines are tinted faint red with a "−" gutter; added lines
// faint green with a "+"; unchanged lines stay plain. The user reads, then
// either applies the rewrite or keeps the original. Low-cortisol: no inline
// word churn, generous spacing, monospace only in the gutter.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/line_diff.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../../../core/widgets/mono_label.dart';

class NodeAiDiffView extends StatelessWidget {
  final String before;
  final String after;
  final String? feedback;

  const NodeAiDiffView({
    super.key,
    required this.before,
    required this.after,
    this.feedback,
  });

  /// Presents the diff sheet. Resolves to `true` when the user applies the
  /// rewrite, `false`/`null` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String before,
    required String after,
    String? feedback,
  }) {
    final c = RecallColors.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NodeAiDiffView(
        before: before,
        after: after,
        feedback: feedback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final diff = LineDiff.compute(before, after);
    final removed = diff.where((d) => d.op == DiffOp.removed).length;
    final added = diff.where((d) => d.op == DiffOp.added).length;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _header(c, removed, added),
            if (feedback != null && feedback!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  feedback!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.grey600,
                    height: 1.5,
                  ),
                ),
              ),
            Divider(height: 1, color: c.grey200),
            Flexible(child: _diffBody(c, diff)),
            Divider(height: 1, color: c.grey200),
            _actions(context, c),
          ],
        ),
      ),
    );
  }

  Widget _header(RecallColors c, int removed, int added) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.canvas,
              shape: BoxShape.circle,
              border: Border.all(color: c.grey200),
            ),
            child: const AuraMark(size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review ${AuraBrand.name}\u2019s rewrite',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _countTag(c, '\u2212$removed', c.chipRed),
                    const SizedBox(width: 8),
                    _countTag(c, '+$added', c.chipGreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countTag(RecallColors c, String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.04,
      ),
    );
  }

  Widget _diffBody(RecallColors c, List<DiffLine> diff) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: diff.length,
      itemBuilder: (_, i) => _line(c, diff[i]),
    );
  }

  Widget _line(RecallColors c, DiffLine d) {
    Color? bg;
    Color gutterColor = c.grey400;
    String gutter = ' ';
    Color textColor = c.grey600;

    switch (d.op) {
      case DiffOp.removed:
        bg = c.chipRed.withValues(alpha: 0.08);
        gutterColor = c.chipRed;
        gutter = '\u2212';
        textColor = c.grey600;
        break;
      case DiffOp.added:
        bg = c.chipGreen.withValues(alpha: 0.10);
        gutterColor = c.chipGreen;
        gutter = '+';
        textColor = c.ink;
        break;
      case DiffOp.equal:
        bg = null;
        break;
    }

    // Blank lines still need height so paragraph spacing reads correctly.
    final text = d.text.isEmpty ? ' ' : d.text;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              gutter,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: gutterColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: textColor,
                height: 1.5,
                decoration: d.op == DiffOp.removed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: c.chipRed.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, RecallColors c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Keep original',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.grey600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.inkOnInk,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Apply rewrite',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.inkOnInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MonoLabel('you can revert anytime',
                      color: c.inkOnInk.withValues(alpha: 0.6),
                      size: 8.5,
                      tracking: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
