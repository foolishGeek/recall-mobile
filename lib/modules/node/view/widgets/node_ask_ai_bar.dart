import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../data/models/ai_results.dart';

class NodeAskAiBar extends StatefulWidget {
  final String modelLabel;
  final bool isLoading;
  final RagChatResult? result;
  final String? error;
  final ValueChanged<String> onSend;
  final VoidCallback onClear;

  const NodeAskAiBar({
    super.key,
    required this.modelLabel,
    required this.isLoading,
    this.result,
    this.error,
    required this.onSend,
    required this.onClear,
  });

  @override
  State<NodeAskAiBar> createState() => _NodeAskAiBarState();
}

class _NodeAskAiBarState extends State<NodeAskAiBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final q = _ctrl.text.trim();
    if (q.isEmpty || widget.isLoading) return;
    RecallHaptics.selection();
    widget.onSend(q);
    _ctrl.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.result != null || widget.error != null)
          _responseCard(c),
        _gradientMask(c),
        _inputBar(c),
      ],
    );
  }

  Widget _responseCard(RecallColors c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: c.grey500),
              const SizedBox(width: 6),
              Text(
                'AI RESPONSE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: c.grey500,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onClear,
                child: Icon(Icons.close, size: 16, color: c.grey400),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.error ?? widget.result?.answer ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: widget.error != null ? Colors.redAccent : c.ink,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientMask(RecallColors c) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.canvas.withValues(alpha: 0),
            c.canvas,
          ],
        ),
      ),
    );
  }

  Widget _inputBar(RecallColors c) {
    return Container(
      color: c.canvas,
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.grey200),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.auto_awesome, size: 18, color: c.grey400),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: GoogleFonts.inter(fontSize: 14, color: c.ink),
                    decoration: InputDecoration(
                      hintText: 'Ask AI about this node...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 14, color: c.grey400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                _modelBadge(c),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.isLoading ? c.grey200 : c.ink,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.grey500,
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: c.inkOnInk,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'FREE + PREMIUM · NO LOCK ON AI',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: c.grey400,
              letterSpacing: 0.16 * 8.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelBadge(RecallColors c) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border.all(color: c.grey200),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        widget.modelLabel.split('-').first.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: c.grey600,
          letterSpacing: 0.1 * 9,
        ),
      ),
    );
  }
}
