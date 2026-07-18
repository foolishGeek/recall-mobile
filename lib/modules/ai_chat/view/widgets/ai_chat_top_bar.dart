// Top bar: back chevron · centered "Ask Recall" (Fraunces) with a mono scope pill
// underneath ("● YOUR {N} NODES") · trailing menu glyph. Hairline bottom border.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class AiChatTopBar extends StatelessWidget {
  final int nodeCount;
  final VoidCallback onBack;
  final VoidCallback? onMenu;

  const AiChatTopBar({
    super.key,
    required this.nodeCount,
    required this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.grey200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.chevron_left, size: 22, color: c.grey600),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ask Aura',
                  style: t.headingSm.copyWith(
                    color: c.ink,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.ink.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    MonoLabel('Your $nodeCount ${nodeCount == 1 ? 'note' : 'notes'}',
                        color: c.grey500, size: 9.5, tracking: 0.16),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMenu,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.tune_rounded, size: 18, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
