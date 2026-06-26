// The quiet composer: a single rounded field + one round send button that flips
// to solid ink once the field has text. A 240ms focus transition on the border,
// and a permanent mono reassurance line beneath [S20 §9 / design].

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class AiComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool offline;

  const AiComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.offline = false,
  });

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onText);
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  void _onText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    final sendActive = _hasText && !widget.offline;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.grey200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: RecallMotion.normal,
            curve: RecallMotion.easeOut,
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _focused ? c.ink : c.grey200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: !widget.offline,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                    style: t.body.copyWith(color: c.ink),
                    cursorColor: c.ink,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: InputBorder.none,
                      hintText: 'Ask anything you\u2019ve written\u2026',
                      hintStyle: t.body.copyWith(color: c.grey500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: sendActive ? widget.onSend : null,
                  child: AnimatedContainer(
                    duration: RecallMotion.fast,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sendActive ? c.ink : c.cardSunken,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: sendActive ? c.inkOnInk : c.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MonoLabel(
            widget.offline
                ? 'You\u2019re offline — connect to ask your notes'
                : 'Grounded in your notes, enriched by Aura',
            color: c.grey400,
            size: 9.5,
            tracking: 0.16,
          ),
        ],
      ),
    );
  }
}
