// Cooldown interstitial [D-UI-1]: premium fair-use cooldown reached. Offers an
// explicit "Continue with 1 credit" when the balance allows, otherwise points to
// buying more. Reads the server `cooldown_until` + `profiles.ai_credit_balance`.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class AiCooldownSheet extends StatelessWidget {
  final DateTime? cooldownUntil;
  final int creditBalance;
  final VoidCallback onContinue;
  final VoidCallback onBuyCredits;

  const AiCooldownSheet({
    super.key,
    required this.cooldownUntil,
    required this.creditBalance,
    required this.onContinue,
    required this.onBuyCredits,
  });

  bool get _canSpend => creditBalance >= 1;

  String get _backIn {
    final until = cooldownUntil;
    if (until == null) return 'Back again soon';
    final left = until.difference(DateTime.now());
    if (left.isNegative) return 'Ready now';
    final h = left.inHours;
    final m = left.inMinutes % 60;
    if (h > 0) return 'Back in ${h}h ${m}m';
    return 'Back in ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.grey200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(_backIn, color: c.grey500, size: 9.5, tracking: 0.2),
            const SizedBox(height: 12),
            Text('Take a breather.',
                style: t.headingMd.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Text(
              'You\u2019ve asked a lot this hour. Spend a credit to keep going '
              'now, or come back when the break ends.',
              style: t.body.copyWith(color: c.grey600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.bolt_outlined, size: 15, color: c.grey500),
                const SizedBox(width: 6),
                MonoLabel('$creditBalance credits', color: c.grey500, size: 10),
              ],
            ),
            const SizedBox(height: 18),
            if (_canSpend) ...[
              _PrimaryButton(
                label: 'Continue with 1 credit',
                onTap: onContinue,
                color: c.ink,
                textColor: c.inkOnInk,
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                label: 'Buy credits',
                onTap: onBuyCredits,
                color: c.card,
                textColor: c.ink,
                border: c.grey200,
              ),
            ] else
              _PrimaryButton(
                label: 'Buy credits',
                onTap: onBuyCredits,
                color: c.ink,
                textColor: c.inkOnInk,
              ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? border;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecallType.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Text(label, style: t.label.copyWith(color: textColor)),
      ),
    );
  }
}
