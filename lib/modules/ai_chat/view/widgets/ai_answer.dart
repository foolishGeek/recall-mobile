// One AI answer block: animated Aura mark + "Aura — drafted from your notes"
// label, the editorial body, source chips, and a footer with the Aura
// attribution + thumbs feedback + ghost copy/regenerate actions. While streaming
// it shows the GENERATING pulse + Stop and hides the actions.

import 'package:flutter/material.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../data/models/models.dart';
import 'ai_answer_body.dart';
import 'ai_generating_pulse.dart';
import 'ai_model_tag.dart';
import 'ai_source_chips.dart';

class AiAnswer extends StatelessWidget {
  final String text;
  final List<RagCitation> citations;
  final String? model;
  final bool streaming;
  final VoidCallback onStop;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;
  final ValueChanged<RagCitation> onSourceTap;

  /// Thumbs feedback [D-AI-6]: current rating (-1/0/+1) and the tap handler.
  /// When [onRate] is null (e.g. the live streaming answer) thumbs are hidden.
  final int rating;
  final ValueChanged<int>? onRate;

  const AiAnswer({
    super.key,
    required this.text,
    required this.citations,
    required this.model,
    required this.streaming,
    required this.onStop,
    required this.onCopy,
    required this.onRegenerate,
    required this.onSourceTap,
    this.rating = 0,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(streaming: streaming),
        const SizedBox(height: 14),
        AiAnswerBody(text: text),
        if (streaming) ...[
          const SizedBox(height: 16),
          AiGeneratingPulse(onStop: onStop),
        ],
        if (!streaming && citations.isNotEmpty) ...[
          const SizedBox(height: 18),
          AiSourceChips(citations: citations, onTap: onSourceTap),
        ],
        const SizedBox(height: 18),
        Container(height: 1, color: c.grey200),
        const SizedBox(height: 12),
        Row(
          children: [
            AiModelTag(model: model, streaming: streaming),
            const Spacer(),
            if (!streaming) ...[
              if (onRate != null) ...[
                _ThumbAction(
                  icon: Icons.thumb_up_outlined,
                  active: rating == 1,
                  onTap: () => onRate!(1),
                ),
                _ThumbAction(
                  icon: Icons.thumb_down_outlined,
                  active: rating == -1,
                  onTap: () => onRate!(-1),
                ),
                const SizedBox(width: 2),
              ],
              _GhostAction(icon: Icons.refresh, onTap: onRegenerate),
              _GhostAction(icon: Icons.copy_outlined, onTap: onCopy),
            ],
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final bool streaming;

  const _Header({required this.streaming});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: c.grey200),
          ),
          child: AuraMark(size: 15, animate: streaming),
        ),
        const SizedBox(width: 8),
        MonoLabel('${AuraBrand.name} — drafted from your notes',
            color: c.grey500, size: 9.5, tracking: 0.16),
      ],
    );
  }
}

class _ThumbAction extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ThumbAction({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 14, color: active ? c.ink : c.grey400),
      ),
    );
  }
}

class _GhostAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GhostAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 15, color: c.grey500),
      ),
    );
  }
}
