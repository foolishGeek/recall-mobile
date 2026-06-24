// Recall · inline error card (Block B1 standard error state). Quiet card with a
// calm message + Retry. Used by RecallStateView and any data-backed screen.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';
import 'recall_button.dart';
import 'soft_card.dart';

class RecallErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RecallErrorCard({
    super.key,
    this.message = "Couldn't reach the server — try again",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 14, height: 1.5, color: c.grey600),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            SecondaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
