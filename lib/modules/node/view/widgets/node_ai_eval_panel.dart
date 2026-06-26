import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../core/widgets/recall_skeleton.dart';

class NodeAiEvalPanel extends StatefulWidget {
  final int qualityScore;
  final double qualityProgress;
  final String scoreDisplay;
  final String suggestedComfortLabel;
  final NeoLevel suggestedComfortLevel;
  final String? feedback;
  final String modelLabel;
  final bool isLoading;
  final bool overviewLocked;
  final bool hasSuggestion;
  final String quotaLabel;
  final VoidCallback onApply;
  final VoidCallback onRegenerate;
  final int rating;
  final ValueChanged<int>? onRate;

  const NodeAiEvalPanel({
    super.key,
    required this.qualityScore,
    required this.qualityProgress,
    required this.scoreDisplay,
    required this.suggestedComfortLabel,
    required this.suggestedComfortLevel,
    required this.feedback,
    required this.modelLabel,
    required this.isLoading,
    required this.overviewLocked,
    required this.hasSuggestion,
    required this.quotaLabel,
    required this.onApply,
    required this.onRegenerate,
    this.rating = 0,
    this.onRate,
  });

  @override
  State<NodeAiEvalPanel> createState() => _NodeAiEvalPanelState();
}

class _NodeAiEvalPanelState extends State<NodeAiEvalPanel>
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
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: c.ink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.isLoading ? _skeleton() : _content(c),
      ),
    );
  }

  Widget _skeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecallSkeleton(width: 120, height: 12),
        SizedBox(height: 16),
        RecallSkeleton(width: 80, height: 36),
        SizedBox(height: 12),
        RecallSkeleton(height: 6),
        SizedBox(height: 18),
        RecallSkeleton(width: 90, height: 24),
        SizedBox(height: 10),
        RecallSkeleton(height: 12),
        SizedBox(height: 4),
        RecallSkeleton(width: 200, height: 12),
      ],
    );
  }

  Widget _content(RecallColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c),
        const SizedBox(height: 14),
        _scoreAndComfortRow(c),
        if (widget.feedback != null && widget.feedback!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            widget.feedback!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.grey600,
              height: 1.55,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _actions(c),
        if (widget.overviewLocked) ...[
          const SizedBox(height: 14),
          _quotaLock(c),
        ],
      ],
    );
  }

  Widget _header(RecallColors c) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.canvas,
            shape: BoxShape.circle,
            border: Border.all(color: c.grey200),
          ),
          child: const AuraMark(size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          '${AuraBrand.name.toUpperCase()} EVALUATION',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: c.grey500,
            letterSpacing: 0.18 * 9.5,
          ),
        ),
        const Spacer(),
        if (widget.onRate != null) ...[
          _ThumbAction(
            up: true,
            active: widget.rating == 1,
            onTap: () => widget.onRate!(1),
          ),
          const SizedBox(width: 2),
          _ThumbAction(
            up: false,
            active: widget.rating == -1,
            onTap: () => widget.onRate!(-1),
          ),
        ] else
          Text(
            'just now',
            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: c.grey500),
          ),
      ],
    );
  }

  Widget _scoreAndComfortRow(RecallColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.qualityScore}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 42,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                    letterSpacing: -0.84,
                    height: 1,
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    color: c.grey500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                width: 96,
                child: LinearProgressIndicator(
                  value: widget.qualityProgress.clamp(0.0, 1.0),
                  backgroundColor: c.grey200,
                  color: c.ink,
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'SUGGESTED COMFORT',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: c.grey500,
                letterSpacing: 0.18,
              ),
            ),
            const SizedBox(height: 6),
            NeoChip.priority(
              widget.suggestedComfortLevel,
              label: widget.suggestedComfortLabel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actions(RecallColors c) {
    final canAct = !widget.overviewLocked;
    return Row(
      children: [
        Expanded(
          child: widget.hasSuggestion
              ? FilledButton(
                  onPressed: canAct ? widget.onApply : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.inkOnInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Review rewrite',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.inkOnInk,
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: canAct ? widget.onApply : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.grey200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Apply suggestion',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: widget.overviewLocked ? null : widget.onRegenerate,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.grey200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.refresh_rounded, size: 20, color: c.grey500),
          ),
        ),
      ],
    );
  }

  Widget _quotaLock(RecallColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.grey200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: c.grey500),
          const SizedBox(width: 6),
          Text(
            '${widget.quotaLabel} this month',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: c.grey500,
              letterSpacing: 0.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbAction extends StatelessWidget {
  final bool up;
  final bool active;
  final VoidCallback onTap;

  const _ThumbAction({
    required this.up,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(
          up
              ? (active ? Icons.thumb_up : Icons.thumb_up_outlined)
              : (active ? Icons.thumb_down : Icons.thumb_down_outlined),
          size: 15,
          color: active ? c.ink : c.grey400,
        ),
      ),
    );
  }
}
