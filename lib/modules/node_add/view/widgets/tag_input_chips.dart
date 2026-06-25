import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/tag.dart';

class TagInputChips extends StatelessWidget {
  final List<Tag> tags;
  final TextEditingController controller;
  final ValueChanged<String> onCommit;
  final ValueChanged<Tag> onRemove;

  const TagInputChips({
    super.key,
    required this.tags,
    required this.controller,
    required this.onCommit,
    required this.onRemove,
  });

  void _handleChanged(String value) {
    if (value.contains(' ') || value.contains(',')) {
      final text = value.replaceAll(',', ' ').trim();
      if (text.isNotEmpty) {
        for (final part in text.split(RegExp(r'\s+'))) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) onCommit(trimmed);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...tags.map((tag) => _TagPill(
              tag: tag,
              colors: c,
              onRemove: () => onRemove(tag),
            )),
        SizedBox(
          width: 120,
          height: 30,
          child: TextField(
            controller: controller,
            onChanged: _handleChanged,
            onSubmitted: (t) {
              final trimmed = t.trim();
              if (trimmed.isNotEmpty) onCommit(trimmed);
            },
            style: GoogleFonts.inter(fontSize: 13, color: c.ink),
            decoration: InputDecoration(
              hintText: '+ add tag',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: c.grey400),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  final Tag tag;
  final RecallColors colors;
  final VoidCallback onRemove;

  const _TagPill({
    required this.tag,
    required this.colors,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.cardSunken,
        border: Border.all(color: colors.grey200, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '# ${tag.name}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 13, color: colors.grey500),
          ),
        ],
      ),
    );
  }
}
