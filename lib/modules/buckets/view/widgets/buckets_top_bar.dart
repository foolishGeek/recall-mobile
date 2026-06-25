import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

class BucketsTopBar extends StatelessWidget {
  final VoidCallback onSearchTap;

  const BucketsTopBar({super.key, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      child: Row(
        children: [
          const MonoLabel('Library', size: 11, tracking: 0.16),
          const Spacer(),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.card,
                shape: BoxShape.circle,
                border: Border.all(color: c.grey200),
              ),
              child: Icon(Icons.search, size: 15, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
