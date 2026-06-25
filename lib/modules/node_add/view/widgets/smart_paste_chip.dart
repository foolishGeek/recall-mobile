import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/enums.dart';

class SmartPasteChip extends StatelessWidget {
  final NodeType? detectedType;
  final bool visible;

  const SmartPasteChip({
    super.key,
    required this.detectedType,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -0.5),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.ink,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 9, color: c.inkOnInk),
              const SizedBox(width: 5),
              Text(
                'DETECTED · ${_label(detectedType)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: c.inkOnInk,
                  letterSpacing: 0.1 * 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(NodeType? type) {
    switch (type) {
      case NodeType.link:
        return 'LINK';
      case NodeType.youtube:
        return 'YOUTUBE';
      case NodeType.pdf:
        return 'PDF';
      case NodeType.image:
        return 'IMAGE';
      case NodeType.text:
      case null:
        return 'TEXT';
    }
  }
}
