import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/soft_card.dart';

class QuizModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool locked;
  final VoidCallback onTap;

  const QuizModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SoftCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        sunken: locked,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Hero(
                tag: 'quiz_mode_$title',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.cardSunken,
                    border: Border.all(color: c.grey200),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: c.ink),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: t.headingMd.copyWith(color: c.ink)),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySm.copyWith(color: c.grey600, height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                size: locked ? 14 : 18,
                color: locked ? c.grey500 : c.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
