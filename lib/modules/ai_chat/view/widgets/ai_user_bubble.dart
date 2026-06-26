// The user's question — a right-aligned ink-on-paper bubble, max 78% width, with
// the bottom-right corner shaved to 6px. Fades in over 240ms [S20 §9].

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';

class AiUserBubble extends StatefulWidget {
  final String text;

  const AiUserBubble({super.key, required this.text});

  @override
  State<AiUserBubble> createState() => _AiUserBubbleState();
}

class _AiUserBubbleState extends State<AiUserBubble> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final width = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: RecallMotion.normal,
        curve: RecallMotion.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(
              widget.text,
              style: t.body.copyWith(color: c.inkOnInk, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
