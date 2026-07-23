// Recall · Settings preference editors. Calm slide-up sheets for the Recall Drop
// + Review rows (Reminder style, quiet hours, default cooling, Cards per session).
// Each returns the new value via a callback; the controller owns the write.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/drop_readiness.dart';
import '../../../../core/utils/how_it_works_copy.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/utils/recall_time.dart';
import '../../../../core/widgets/how_it_works_sheet.dart';
import '../../../../core/widgets/memory_strength_selector.dart';
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

class _SheetCaption extends StatelessWidget {
  final String text;
  const _SheetCaption(this.text);
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12.5, height: 1.35, color: c.grey500),
      ),
    );
  }
}

class _HowItWorksLink extends StatelessWidget {
  final String title;
  final List<HowItWorksSection> sections;
  final String? auraPrompt;
  const _HowItWorksLink({
    required this.title,
    required this.sections,
    this.auraPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => showHowItWorksSheet(
          context,
          title: title,
          sections: sections,
          auraPrompt: auraPrompt,
        ),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'How it works',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: c.ink,
            ),
          ),
        ),
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

/// Today empty: explain why the clock ≠ Drop, then expand Reminder style picks.
Future<void> showDropTimingExplainSheet(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onSelected,
}) {
  return _sheet(
    context,
    _DropTimingExplainBody(current: current, onSelected: onSelected),
  );
}

class _DropTimingExplainBody extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const _DropTimingExplainBody({
    required this.current,
    required this.onSelected,
  });

  @override
  State<_DropTimingExplainBody> createState() => _DropTimingExplainBodyState();
}

class _DropTimingExplainBodyState extends State<_DropTimingExplainBody> {
  late String _current = widget.current;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final style = dropStyleName(_current);
    final threshold = dropThresholdFor(_current);
    final isDefault = _current == kDefaultDropFrequency;
    final styleBit = isDefault ? '$style · Default' : style;
    final waitLine = threshold == 1
        ? 'ASAO sends a Drop when even one note is ready.'
        : 'Your style waits for about $threshold notes before a fresh Drop.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Why no Drop yet?'),
        const SizedBox(height: 8),
        Text(
          'The time on Today is when the next notes warm up — not when a Drop '
          'is guaranteed. $waitLine Quiet hours and re-nudge rules can also delay it.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: c.grey600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Current · $styleBit',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            color: c.grey500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            RecallHaptics.selection();
            setState(() => _expanded = !_expanded);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.grey200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Change Reminder style',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 22,
                  color: c.ink,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...kFrequencyOptions.map((o) {
            final isOptDefault = o.$1 == kDefaultDropFrequency;
            return _OptionRow(
              title: isOptDefault ? '${o.$2} · Default' : o.$2,
              subtitle: o.$3,
              selected: o.$1 == _current,
              onTap: () {
                setState(() => _current = o.$1);
                Navigator.pop(context);
                widget.onSelected(o.$1);
              },
            );
          }),
        ],
      ],
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
      const _SheetTitle('Reminder style'),
      const SizedBox(height: 4),
      const _SheetCaption(
        'How insistently Recall Drop nudges you. Pick ASAO if even one note '
        'should trigger a Drop.',
      ),
      const SizedBox(height: 2),
      _HowItWorksLink(
        title: HowItWorksCopy.reminderStyleTitle,
        sections: HowItWorksCopy.reminderStyleSections,
        auraPrompt: 'Explain Reminder style in plain words.',
      ),
      const SizedBox(height: 4),
      ...kFrequencyOptions.map((o) {
        final isDefault = o.$1 == kDefaultDropFrequency;
        return _OptionRow(
          title: isDefault ? '${o.$2} · Default' : o.$2,
          subtitle: o.$3,
          selected: o.$1 == current,
          onTap: () {
            Navigator.pop(context);
            onSelected(o.$1);
          },
        );
      }),
    ]),
  );
}

/// Memory-strength picker (desired retention). [current] is the effective 0..1
/// value; the callback returns the chosen preset retention.
Future<void> showMemoryStrengthSheet(
  BuildContext context, {
  required double current,
  required ValueChanged<double> onSelected,
}) {
  return _sheet(
    context,
    _MemoryStrengthSheetBody(current: current, onSelected: onSelected),
  );
}

class _MemoryStrengthSheetBody extends StatelessWidget {
  final double current;
  final ValueChanged<double> onSelected;
  const _MemoryStrengthSheetBody({
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Memory strength'),
        const SizedBox(height: 12),
        MemoryStrengthSelector(
          value: current,
          usesDefault: false,
          showHowItWorks: true,
          onChanged: (v) {
            Navigator.pop(context);
            onSelected(v);
          },
        ),
      ],
    );
  }
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
  required int tierDefault,
  required bool isPremium,
  required ValueChanged<int?> onSelected,
}) {
  return _sheet(
    context,
    _DailyLimitEditor(
      current: current,
      tierDefault: tierDefault,
      isPremium: isPremium,
      onSelected: onSelected,
    ),
  );
}

class _DailyLimitEditor extends StatefulWidget {
  final int? current;
  final int tierDefault;
  final bool isPremium;
  final ValueChanged<int?> onSelected;
  const _DailyLimitEditor({
    required this.current,
    required this.tierDefault,
    required this.isPremium,
    required this.onSelected,
  });

  @override
  State<_DailyLimitEditor> createState() => _DailyLimitEditorState();
}

class _DailyLimitEditorState extends State<_DailyLimitEditor> {
  late int _value =
      (widget.current ?? widget.tierDefault).clamp(kDailyLimitMin, kDailyLimitMax);
  late bool _usingDefault = widget.current == null;

  void _step(int delta) {
    final next = (_value + delta).clamp(kDailyLimitMin, kDailyLimitMax);
    if (next == _value && !_usingDefault) return;
    RecallHaptics.selection();
    setState(() {
      _value = next;
      _usingDefault = false;
    });
  }

  void _useDefault() {
    RecallHaptics.selection();
    setState(() {
      _value = widget.tierDefault.clamp(kDailyLimitMin, kDailyLimitMax);
      _usingDefault = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final defaultLabel = 'Default(${widget.tierDefault})';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const _SheetTitle('Cards per session'),
      const SizedBox(height: 4),
      const _SheetCaption(
        'How many notes appear in one review session — not when Drops fire. '
        'Drops use Reminder style above.',
      ),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _StepButton(icon: Icons.remove, onTap: () => _step(-kDailyLimitStep)),
        Column(children: [
          Text(
            _usingDefault ? defaultLabel : '$_value',
            style: GoogleFonts.fraunces(
              fontSize: _usingDefault ? 28 : 40,
              fontWeight: FontWeight.w500,
              color: c.ink,
            ),
          ),
          Text(
            'CARDS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: c.grey500,
              letterSpacing: 1.6,
            ),
          ),
        ]),
        _StepButton(icon: Icons.add, onTap: () => _step(kDailyLimitStep)),
      ]),
      const SizedBox(height: 12),
      if (!_usingDefault)
        TextButton(
          onPressed: _useDefault,
          child: Text(
            'Use $defaultLabel',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
        ),
      if (!widget.isPremium) ...[
        const SizedBox(height: 4),
        Text(
          'Free plan reviews up to 8 cards per session.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600),
        ),
      ],
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            RecallHaptics.selection();
            Navigator.pop(context);
            widget.onSelected(_usingDefault ? null : _value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: c.ink,
            foregroundColor: c.inkOnInk,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            'Save',
            style:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
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

/// Calm "Reminders" diagnostic. Reads drop_debug_rpc so the user can see, in
/// plain words, whether a Drop can reach them and why it's quiet — and repair
/// it in one tap when reminders are off / the device isn't registered.
Future<void> showRemindersDiagnosticSheet(
  BuildContext context,
  SettingsController controller,
) {
  // Kick off the check as the sheet opens; the body reacts to the result.
  controller.loadDropDebug();
  return _sheet<void>(
    context,
    Obx(() {
      final c = RecallColors.of(context);
      final d = controller.dropDebug.value;
      final loading = controller.dropDebugLoading.value;

      if (d == null) {
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const _SheetTitle('Reminders'),
          const SizedBox(height: 18),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            const _SheetCaption("Couldn't check just now."),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: controller.loadDropDebug,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Try again',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
              ),
            ),
          ],
        ]);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Reminders'),
          const SizedBox(height: 4),
          _SheetCaption(d.headline),
          const SizedBox(height: 14),
          _DiagRow(label: 'Reminders', value: d.pushOptIn ? 'On' : 'Off'),
          _DiagRow(
            label: 'This device',
            value: d.deviceTokenCount > 0 ? 'Registered' : 'Not registered',
          ),
          _DiagRow(label: 'Style', value: d.reminderStyle),
          _DiagRow(label: 'Next drop', value: _nextDropText(d.nextDropAt)),
          if (d.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "WHY IT'S QUIET",
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5, color: c.grey500, letterSpacing: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            ...d.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                              color: c.grey400, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Text(r,
                            style: GoogleFonts.inter(
                                fontSize: 13.5, height: 1.35, color: c.grey600)),
                      ),
                    ],
                  ),
                )),
          ],
          if (!d.canDeliver) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.repairingReminders.value
                    ? null
                    : () async {
                        final ok = await controller.repairReminders();
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.ink,
                  foregroundColor: c.inkOnInk,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: controller.repairingReminders.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Turn on reminders',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      );
    }),
  );
}

/// Compact, honest next-drop readout for the diagnostic (or an em-dash).
String _nextDropText(DateTime? at) {
  if (at == null) return '—';
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = day.difference(today).inDays;
  final clock = RecallTime.clock12h(local);
  if (diff <= 0) return 'Today · $clock';
  if (diff == 1) return 'Tomorrow · $clock';
  if (diff < 7) return 'In $diff days · $clock';
  return clock;
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  const _DiagRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 14, color: c.grey600)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
        ],
      ),
    );
  }
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
