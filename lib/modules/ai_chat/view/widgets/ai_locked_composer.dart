// Locked composer states. Downgraded -> "AI unavailable — resubscribe to
// continue". Free past the monthly quota -> "Monthly AI limit reached" with a
// quiet upgrade CTA [D-AI-4]. No calls are made from a locked composer.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class AiLockedComposer extends StatelessWidget {
  final String reason;
  final bool showUpgrade;
  final String? quotaLabel;
  final VoidCallback onUpgrade;

  const AiLockedComposer({
    super.key,
    required this.reason,
    required this.showUpgrade,
    required this.onUpgrade,
    this.quotaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.grey200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.cardSunken,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.grey200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 15, color: c.grey500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reason,
                    style: t.body.copyWith(color: c.grey600, height: 1.3),
                  ),
                ),
                if (showUpgrade)
                  GestureDetector(
                    onTap: onUpgrade,
                    child: MonoLabel('Upgrade', color: c.ink, size: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MonoLabel(
            quotaLabel == null ? 'Grounded in your notes, enriched by Aura'
                : '$quotaLabel requests used this month',
            color: c.grey400,
            size: 9.5,
            tracking: 0.16,
          ),
        ],
      ),
    );
  }
}
