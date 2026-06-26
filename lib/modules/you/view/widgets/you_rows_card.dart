// Recall · You rows. Tidy navigation rows: Settings (push) for everyone, plus
// Manage subscription (native OS subscription management) for premium. ListRow
// emits the selection tick + chevron, matching the standard profile/settings row.

import 'package:flutter/material.dart';

import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/soft_card.dart';

class YouRowsCard extends StatelessWidget {
  final bool premium;
  final VoidCallback onSettings;
  final VoidCallback onManageSubscription;

  const YouRowsCard({
    super.key,
    required this.premium,
    required this.onSettings,
    required this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        children: [
          ListRow(
            title: 'Settings',
            leading: Icons.settings_outlined,
            divider: premium,
            onTap: onSettings,
          ),
          if (premium)
            ListRow(
              title: 'Manage subscription',
              leading: Icons.credit_card_outlined,
              divider: false,
              onTap: onManageSubscription,
            ),
        ],
      ),
    );
  }
}
