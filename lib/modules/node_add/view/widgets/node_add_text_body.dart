import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';

class NodeAddTextBody extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const NodeAddTextBody({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarkdownToolbar(ink: c.ink, grey400: c.grey400, textController: controller),
        _WhisperTip(colors: c, textController: controller),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: null,
          minLines: 8,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: c.ink,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: 'What did you learn?',
            hintStyle: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: c.grey400,
              height: 1.6,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// ── Markdown toolbar ──

class _MarkdownToolbar extends StatelessWidget {
  final Color ink;
  final Color grey400;
  final TextEditingController textController;

  const _MarkdownToolbar({
    required this.ink,
    required this.grey400,
    required this.textController,
  });

  static const _actions = [
    (Icons.format_bold, '**', '**'),
    (Icons.format_italic, '_', '_'),
    (Icons.format_list_bulleted, '\n- ', ''),
    (Icons.format_list_numbered, '\n1. ', ''),
    (Icons.code, '`', '`'),
    (Icons.link, '[', '](url)'),
  ];

  void _insertMarkdown(String prefix, String suffix) {
    final selection = textController.selection;
    final text = textController.text;
    final start = selection.start;
    final end = selection.end;

    if (start < 0) {
      final newText = text + prefix + suffix;
      textController.value = textController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      RecallHaptics.selection();
      return;
    }

    String newText;
    TextSelection newSelection;

    if (selection.isCollapsed) {
      newText = text.substring(0, start) + prefix + suffix + text.substring(start);
      newSelection = TextSelection.collapsed(offset: start + prefix.length);
    } else {
      final selectedText = text.substring(start, end);
      newText = text.substring(0, start) +
          prefix +
          selectedText +
          suffix +
          text.substring(end);
      newSelection = TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      );
    }

    textController.value = textController.value.copyWith(
      text: newText,
      selection: newSelection,
    );
    RecallHaptics.selection();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: _actions
            .map((action) => GestureDetector(
                  onTap: () => _insertMarkdown(action.$2, action.$3),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(action.$1, size: 18, color: grey400),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Whisper tip ──

class _WhisperTip extends StatefulWidget {
  final RecallColors colors;
  final TextEditingController textController;

  const _WhisperTip({required this.colors, required this.textController});

  @override
  State<_WhisperTip> createState() => _WhisperTipState();
}

class _WhisperTipState extends State<_WhisperTip> {
  static const _tips = [
    '**bold**  _italic_  ~strike~',
    '- bullet  1. numbered  > quote',
    '`code`  [text](url)',
    'select text, then tap a button above',
  ];

  int _tipIndex = 0;
  bool _dismissed = false;
  bool _hasText = false;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
    _hasText = widget.textController.text.isNotEmpty;
    _startRotation();
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _rotateTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final empty = widget.textController.text.isEmpty;
    if (_hasText != !empty) {
      setState(() => _hasText = !empty);
    }
  }

  void _startRotation() {
    _rotateTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_dismissed && !_hasText && mounted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = !_dismissed && !_hasText;
    return AnimatedOpacity(
      opacity: visible ? 0.72 : 0.0,
      duration: Duration(milliseconds: visible ? 400 : 600),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: 28,
        child: visible
            ? Row(
                children: [
                  Text(
                    '*',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: widget.colors.grey400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Text(
                        _tips[_tipIndex],
                        key: ValueKey(_tipIndex),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: widget.colors.grey400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _dismissed = true),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close,
                        size: 10,
                        color: widget.colors.grey300,
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
