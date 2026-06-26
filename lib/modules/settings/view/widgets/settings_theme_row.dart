// Recall · Appearance theme row. A 3-up System / Light / Dark segmented control
// (240ms easeOutCubic, shared selection slide) over the standard grey track —
// active pill is the card surface (docs/12_settings.md · Motion).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../core/utils/recall_haptics.dart';

class SettingsThemeRow extends StatelessWidget {
  final String value; // system | light | dark
  final ValueChanged<String> onChanged;

  const SettingsThemeRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (kThemeSystem, 'System'),
    (kThemeLight, 'Light'),
    (kThemeDark, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Theme', style: GoogleFonts.inter(fontSize: 14, color: c.ink)),
              const Spacer(),
              Text(
                value.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: c.grey500),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? c.canvas : c.grey300,
              border: isDark ? Border.all(color: c.grey300, width: 1) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _options.map((opt) {
                final active = value == opt.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (active) return;
                      RecallHaptics.selection();
                      onChanged(opt.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      height: 34,
                      decoration: BoxDecoration(
                        color: active ? c.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : const [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt.$2,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? c.ink : c.grey600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
