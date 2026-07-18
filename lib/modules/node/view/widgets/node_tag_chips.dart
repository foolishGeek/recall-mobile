import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/tag.dart';

class NodeTagChips extends StatelessWidget {
  final List<Tag> tags;
  final VoidCallback? onAddTap;

  const NodeTagChips({super.key, required this.tags, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty && onAddTap == null) return const SizedBox.shrink();
    final c = RecallColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...tags.map((t) => _TagPill(label: '# ${t.name}', colors: c)),
        if (onAddTap != null)
          _TagPill(label: '+ add', colors: c, onTap: onAddTap),
      ],
    );
  }
}

/// Quiet grey tag pill — exact mockup spec: height 24, padding h10,
/// fontSize 11.5, radius 999, card bg + grey200 border, grey600 text.
class _TagPill extends StatelessWidget {
  final String label;
  final RecallColors colors;
  final VoidCallback? onTap;

  const _TagPill({required this.label, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    // NOTE: no `alignment` here on purpose. A Container with an alignment
    // expands to fill the parent's max width (the full Wrap row), which would
    // force every pill onto its own full-width line. Vertical padding gives the
    // ~24px height while keeping the pill sized to its label so they flow inline.
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.grey200),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: colors.grey600,
        ),
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}
