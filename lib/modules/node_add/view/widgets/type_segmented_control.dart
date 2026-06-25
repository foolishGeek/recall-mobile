import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../data/models/enums.dart';

class TypeSegmentedControl extends StatelessWidget {
  final NodeType selected;
  final ValueChanged<NodeType> onChanged;

  const TypeSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _types = NodeType.values;

  static const _icons = <NodeType, IconData>{
    NodeType.text: Icons.text_snippet_outlined,
    NodeType.link: Icons.link,
    NodeType.youtube: Icons.play_circle_outline,
    NodeType.pdf: Icons.description_outlined,
    NodeType.image: Icons.image_outlined,
  };

  static const _labels = <NodeType, String>{
    NodeType.text: 'Text',
    NodeType.link: 'Link',
    NodeType.youtube: 'YouTube',
    NodeType.pdf: 'PDF',
    NodeType.image: 'Image',
  };

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: _types.map((type) {
          final isActive = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: RecallMotion.easeOut,
                height: 38,
                decoration: BoxDecoration(
                  color: isActive ? c.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icons[type],
                        size: 14,
                        color: isActive ? c.inkOnInk : c.grey600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _labels[type]!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? c.inkOnInk : c.grey600,
                          height: 1,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
