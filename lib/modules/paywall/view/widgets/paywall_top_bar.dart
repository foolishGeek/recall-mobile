// Paywall top bar — close × left · mono "PREMIUM" centered · 32px spacer right.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

class PaywallTopBar extends StatelessWidget {
  final VoidCallback onClose;
  const PaywallTopBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: c.ink, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
          const Spacer(),
          const MonoLabel('Premium', size: 11, tracking: 0.16),
          const Spacer(),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
