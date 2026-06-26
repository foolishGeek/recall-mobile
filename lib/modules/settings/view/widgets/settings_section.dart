// Recall · SettingsSection. A mono section label above a SoftCard of rows —
// the six grouped cards of the Settings screen (docs/12_settings.md).

import 'package:flutter/material.dart';

import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';

class SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(
            label,
            size: 9.5,
            tracking: 0.2,
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 6),
          ),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
