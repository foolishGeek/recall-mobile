// Source chips: grey-on-paper pills naming the nodes the answer was drawn from
// (`citations[]`). Never coloured. Tapping pushes the node detail; a deleted node
// keeps its snapshot title and is a no-op. Overflow collapses into a "+N" chip.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../data/models/models.dart';

class AiSourceChips extends StatelessWidget {
  final List<RagCitation> citations;
  final ValueChanged<RagCitation> onTap;
  final int maxVisible;

  const AiSourceChips({
    super.key,
    required this.citations,
    required this.onTap,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final c = RecallColors.of(context);
    final visible = citations.take(maxVisible).toList();
    final overflow = citations.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel('Drawn from', color: c.grey500, size: 9.5, tracking: 0.2),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final cit in visible)
              _SourceChip(citation: cit, onTap: () => onTap(cit)),
            if (overflow > 0) _OverflowChip(count: overflow),
          ],
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  final RagCitation citation;
  final VoidCallback onTap;

  const _SourceChip({required this.citation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final title = citation.title.isEmpty ? 'Untitled note' : citation.title;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 11, color: c.grey500),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySm.copyWith(color: c.grey600, height: 1.0),
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.north_east, size: 9, color: c.grey400),
          ],
        ),
      ),
    );
  }
}

class _OverflowChip extends StatelessWidget {
  final int count;

  const _OverflowChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.grey400, style: BorderStyle.solid),
      ),
      child: MonoLabel('+$count', color: c.grey500, size: 10, tracking: 0.12),
    );
  }
}
