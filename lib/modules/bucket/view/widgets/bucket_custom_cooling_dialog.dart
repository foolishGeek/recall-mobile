import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/utils/recall_haptics.dart';

/// Prompts for a custom cooling-period length in days. Returns the chosen day
/// count, or null if dismissed. Kept minimal: a − [ N ] + stepper with a small
/// row of quick presets, styled with theme tokens only.
Future<int?> showCustomCoolingDialog({
  required BuildContext context,
  int initialDays = 14,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _CustomCoolingDialog(initialDays: initialDays),
  );
}

const int _minDays = 1;
const int _maxDays = 365;

class _CustomCoolingDialog extends StatefulWidget {
  final int initialDays;

  const _CustomCoolingDialog({required this.initialDays});

  @override
  State<_CustomCoolingDialog> createState() => _CustomCoolingDialogState();
}

class _CustomCoolingDialogState extends State<_CustomCoolingDialog> {
  late int _days = widget.initialDays.clamp(_minDays, _maxDays);

  void _set(int value) {
    final next = value.clamp(_minDays, _maxDays);
    if (next == _days) return;
    RecallHaptics.selection();
    setState(() => _days = next);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Custom cooling',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: c.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long should notes rest before they come back?',
            style: GoogleFonts.inter(fontSize: 13.5, color: c.grey600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => _set(_days - 1),
                c: c,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_days',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -1,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _days == 1 ? 'day' : 'days',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: c.grey500,
                        letterSpacing: 0.16 * 11,
                      ),
                    ),
                  ],
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => _set(_days + 1),
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 21, 45, 60, 90]
                .map((d) => _PresetChip(
                      days: d,
                      active: _days == d,
                      onTap: () => _set(d),
                      c: c,
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: c.grey600, fontSize: 14)),
        ),
        TextButton(
          onPressed: () {
            RecallHaptics.light();
            Navigator.pop(context, _days);
          },
          child: Text('Set',
              style: GoogleFonts.inter(
                  color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final RecallColors c;

  const _StepButton({required this.icon, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.canvas,
          border: Border.all(color: c.grey200),
          borderRadius: BorderRadius.circular(RecallShape.radiusMd),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: c.ink),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int days;
  final bool active;
  final VoidCallback onTap;
  final RecallColors c;

  const _PresetChip({
    required this.days,
    required this.active,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.ink : c.canvas,
          border: Border.all(color: active ? c.ink : c.grey200),
          borderRadius: BorderRadius.circular(RecallShape.radiusSm),
        ),
        child: Text(
          '${days}d',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? c.inkOnInk : c.grey600,
          ),
        ),
      ),
    );
  }
}
