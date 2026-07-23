import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/soft_card.dart';

/// The calm entry point that replaces the always-open config on the main bucket
/// screen. Shows a plain-English recipe readout ("Balanced · gentle reminders ·
/// rests 14 days") so config is understandable at a glance, plus the Spaced
/// revision master toggle. Tapping anywhere but the toggle opens Bucket config.
///
/// The one earned color: a small comfort-green check next to the title, shown
/// only when spaced revision is on — meaning "this bucket is actively
/// remembering for you".
class RecallSetupEntry extends StatelessWidget {
  final bool srEnabled;
  final bool disabled;
  final String recipe;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenConfig;

  const RecallSetupEntry({
    super.key,
    required this.srEnabled,
    required this.disabled,
    required this.recipe,
    required this.onToggle,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onOpenConfig,
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.tune_rounded,
                size: 20, color: srEnabled ? c.ink : c.grey500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recall setup',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      if (srEnabled) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded,
                            size: 15, color: c.chipGreen),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    srEnabled ? recipe : 'Notes stay as quiet reference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: c.grey500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // The toggle is a separate hit target — tapping it never opens config.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Row(
                children: [
                  RecallToggle(value: srEnabled, onChanged: onToggle),
                  if (srEnabled) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: c.grey400),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
