// Recall · Settings preference editors. Calm slide-up sheets for the Recall Drop
// + Review rows (frequency, quiet hours, default cooling, daily review limit).
// Each returns the new value via a callback; the controller owns the write.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../controller/settings_controller.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  final c = RecallColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Grip(),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    ),
  );
}

class _Grip extends StatelessWidget {
  const _Grip();
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      width: 36,
      height: 4,
      decoration:
          BoxDecoration(color: c.grey400, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String text;
  const _SheetTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.fraunces(
            fontSize: 22, fontWeight: FontWeight.w500, color: c.ink),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        RecallHaptics.selection();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, color: c.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5, color: c.grey500)),
              ],
            ]),
          ),
          if (selected) Icon(Icons.check, size: 18, color: c.ink),
        ]),
      ),
    );
  }
}

Future<void> showFrequencySheet(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onSelected,
}) {
  return _sheet(
    context,
    Column(mainAxisSize: MainAxisSize.min, children: [
      const _SheetTitle('Drop frequency'),
      const SizedBox(height: 6),
      ...kFrequencyOptions.map((o) => _OptionRow(
            title: o.$2,
            subtitle: o.$3,
            selected: o.$1 == current,
            onTap: () {
              Navigator.pop(context);
              onSelected(o.$1);
            },
          )),
    ]),
  );
}

Future<void> showCoolingSheet(
  BuildContext context, {
  required int currentDays,
  required ValueChanged<int> onSelected,
}) {
  return _sheet(
    context,
    Column(mainAxisSize: MainAxisSize.min, children: [
      const _SheetTitle('Default cooling period'),
      const SizedBox(height: 6),
      ...kCoolingDayOptions.map((d) => _OptionRow(
            title: d == 1 ? '1 day' : '$d days',
            selected: d == currentDays,
            onTap: () {
              Navigator.pop(context);
              onSelected(d);
            },
          )),
    ]),
  );
}

Future<void> showDailyLimitSheet(
  BuildContext context, {
  required int? current,
  required bool isPremium,
  required ValueChanged<int> onSelected,
}) {
  return _sheet(
    context,
    _DailyLimitEditor(
      current: current ?? kDailyLimitMin,
      isPremium: isPremium,
      onSelected: onSelected,
    ),
  );
}

class _DailyLimitEditor extends StatefulWidget {
  final int current;
  final bool isPremium;
  final ValueChanged<int> onSelected;
  const _DailyLimitEditor({
    required this.current,
    required this.isPremium,
    required this.onSelected,
  });

  @override
  State<_DailyLimitEditor> createState() => _DailyLimitEditorState();
}

class _DailyLimitEditorState extends State<_DailyLimitEditor> {
  late int _value = widget.current.clamp(kDailyLimitMin, kDailyLimitMax);

  void _step(int delta) {
    final next = (_value + delta).clamp(kDailyLimitMin, kDailyLimitMax);
    if (next == _value) return;
    RecallHaptics.selection();
    setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const _SheetTitle('Daily review limit'),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _StepButton(icon: Icons.remove, onTap: () => _step(-kDailyLimitStep)),
        Column(children: [
          Text('$_value',
              style: GoogleFonts.fraunces(
                  fontSize: 40, fontWeight: FontWeight.w500, color: c.ink)),
          Text('CARDS',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: c.grey500, letterSpacing: 1.6)),
        ]),
        _StepButton(icon: Icons.add, onTap: () => _step(kDailyLimitStep)),
      ]),
      const SizedBox(height: 16),
      if (!widget.isPremium)
        Text('Free plan reviews up to 8 cards per session.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600)),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            RecallHaptics.selection();
            Navigator.pop(context);
            widget.onSelected(_value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: c.ink,
            foregroundColor: c.inkOnInk,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Save',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: c.grey300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: c.ink, size: 22),
      ),
    );
  }
}

/// Quiet hours: pick start then end (cancel at either step keeps the prior
/// value). A "Turn off" action clears both → "no quiet hours".
Future<void> showQuietHoursSheet(
  BuildContext context, {
  required String? start,
  required String? end,
  required void Function(String? start, String? end) onChanged,
}) async {
  final c = RecallColors.of(context);
  await _sheet<void>(
    context,
    Column(mainAxisSize: MainAxisSize.min, children: [
      const _SheetTitle('Quiet hours'),
      const SizedBox(height: 2),
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('No Recall Drops are sent during these hours.',
              style: GoogleFonts.inter(fontSize: 13, color: c.grey600)),
        ),
      ),
      const SizedBox(height: 10),
      _OptionRow(
        title: 'Set quiet hours',
        selected: false,
        onTap: () async {
          Navigator.pop(context);
          final s = await showTimePicker(
            context: context,
            initialTime: _parseTod(start) ?? const TimeOfDay(hour: 22, minute: 0),
            helpText: 'Quiet hours start',
          );
          if (s == null || !context.mounted) return;
          final e = await showTimePicker(
            context: context,
            initialTime: _parseTod(end) ?? const TimeOfDay(hour: 8, minute: 0),
            helpText: 'Quiet hours end',
          );
          if (e == null) return;
          onChanged(_todToWire(s), _todToWire(e));
        },
      ),
      _OptionRow(
        title: 'Turn off',
        selected: start == null || end == null || start == end,
        onTap: () {
          Navigator.pop(context);
          onChanged(null, null);
        },
      ),
    ]),
  );
}

TimeOfDay? _parseTod(String? wire) {
  if (wire == null || wire.length < 5) return null;
  final h = int.tryParse(wire.substring(0, 2));
  final m = int.tryParse(wire.substring(3, 5));
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _todToWire(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
