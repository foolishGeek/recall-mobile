// Recall · pick which bits of Aura's answer to tuck into the note.
// Low-cortisol: soft selectable cards, all on by default, one calm apply CTA.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/utils/answer_segments.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/aura_mark.dart';

class NodeAskAiUpdateSheet extends StatefulWidget {
  final String answer;

  const NodeAskAiUpdateSheet({super.key, required this.answer});

  /// Returns the joined excerpt the user kept, or null if cancelled.
  static Future<String?> show(BuildContext context, {required String answer}) {
    final c = RecallColors.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NodeAskAiUpdateSheet(answer: answer),
    );
  }

  @override
  State<NodeAskAiUpdateSheet> createState() => _NodeAskAiUpdateSheetState();
}

class _NodeAskAiUpdateSheetState extends State<NodeAskAiUpdateSheet> {
  late final List<String> _segments;
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _segments = splitAnswerSegments(widget.answer);
    // All on by default — deselect what you don't want. Feels generous, not
    // like homework.
    _selected = {for (var i = 0; i < _segments.length; i++) i};
  }

  String get _excerpt {
    final parts = <String>[];
    for (var i = 0; i < _segments.length; i++) {
      if (_selected.contains(i)) parts.add(_segments[i]);
    }
    return parts.join('\n\n').trim();
  }

  void _toggle(int i) {
    RecallHaptics.selection();
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  void _selectAll() {
    RecallHaptics.selection();
    setState(() {
      _selected
        ..clear()
        ..addAll({for (var i = 0; i < _segments.length; i++) i});
    });
  }

  void _clearAll() {
    RecallHaptics.selection();
    setState(_selected.clear);
  }

  void _apply() {
    final text = _excerpt;
    if (text.isEmpty) return;
    RecallHaptics.medium();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height - keyboard;
    final count = _selected.length;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight * 0.92),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AuraMark(size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Update note',
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap what to keep — ${AuraBrand.name} will tuck it into '
                      'this note. Leave out the rest.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.grey600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    Text(
                      count == 0
                          ? 'Nothing selected'
                          : '$count of ${_segments.length} kept',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: c.grey500,
                        letterSpacing: 0.14 * 10,
                      ),
                    ),
                    const Spacer(),
                    _QuietLink(
                      label: 'All',
                      onTap: _selectAll,
                      colors: c,
                    ),
                    const SizedBox(width: 14),
                    _QuietLink(
                      label: 'None',
                      onTap: _clearAll,
                      colors: c,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  shrinkWrap: true,
                  itemCount: _segments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final on = _selected.contains(i);
                    return _SegmentCard(
                      text: _segments[i],
                      selected: on,
                      onTap: () => _toggle(i),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: c.grey200),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 48,
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: c.grey600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: count == 0 ? null : _apply,
                        child: AnimatedOpacity(
                          opacity: count == 0 ? 0.4 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: c.ink,
                              borderRadius: BorderRadius.circular(
                                RecallShape.radiusMd,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Add to note',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: c.inkOnInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final RecallColors colors;

  const _QuietLink({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: colors.ink,
        ),
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: selected ? c.canvas : c.cardSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.ink.withValues(alpha: 0.55) : c.grey200,
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.ink : Colors.transparent,
                  border: Border.all(
                    color: selected ? c.ink : c.grey400,
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(Icons.check, size: 11, color: c.inkOnInk)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: selected ? c.ink : c.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
