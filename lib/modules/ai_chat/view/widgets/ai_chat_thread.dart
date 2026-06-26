// The scrolling thread: a day label, the alternating question/answer turns, the
// in-flight answer (searching dots -> streaming text), an inline retry on a
// transient failure, and the empty-state suggested prompts. Auto-scrolls to the
// newest content. Pure render driven by controller state.

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../data/models/models.dart';
import '../../controller/ai_chat_controller.dart';
import '../../controller/ai_chat_turn.dart';
import 'ai_answer.dart';
import 'ai_suggested_prompts.dart';
import 'ai_user_bubble.dart';

class AiChatThread extends StatefulWidget {
  final List<AiChatTurn> turns;
  final AnswerPhase phase;
  final String streamText;
  final List<RagCitation> liveCitations;
  final String? liveModel;
  final String? answerError;
  final bool showSuggestions;
  final VoidCallback onStop;
  final VoidCallback onRegenerate;
  final VoidCallback onRetry;
  final ValueChanged<String> onSuggested;
  final ValueChanged<String> onCopy;
  final ValueChanged<RagCitation> onSourceTap;
  final void Function(AiChatTurn turn, int rating)? onRate;

  const AiChatThread({
    super.key,
    required this.turns,
    required this.phase,
    required this.streamText,
    required this.liveCitations,
    required this.liveModel,
    required this.answerError,
    required this.showSuggestions,
    required this.onStop,
    required this.onRegenerate,
    required this.onRetry,
    required this.onSuggested,
    required this.onCopy,
    required this.onSourceTap,
    this.onRate,
  });

  @override
  State<AiChatThread> createState() => _AiChatThreadState();
}

class _AiChatThreadState extends State<AiChatThread> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(AiChatThread old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      children: [
        Center(
          child: MonoLabel('— Today —', color: c.grey400, size: 9.5, tracking: 0.2),
        ),
        const SizedBox(height: 18),
        if (widget.showSuggestions)
          AiSuggestedPrompts(onTap: widget.onSuggested),
        for (final turn in widget.turns) ...[
          _turn(turn),
          const SizedBox(height: 26),
        ],
        if (widget.phase == AnswerPhase.searching) const _SearchingRow(),
        if (widget.phase == AnswerPhase.streaming)
          AiAnswer(
            text: widget.streamText,
            citations: widget.liveCitations,
            model: widget.liveModel,
            streaming: true,
            onStop: widget.onStop,
            onCopy: () {},
            onRegenerate: () {},
            onSourceTap: widget.onSourceTap,
          ),
        if (widget.answerError != null) _ErrorRow(
          message: widget.answerError!,
          onRetry: widget.onRetry,
        ),
      ],
    );
  }

  Widget _turn(AiChatTurn turn) {
    if (turn.isUser) return AiUserBubble(text: turn.text);
    return AiAnswer(
      text: turn.text,
      citations: turn.citations,
      model: turn.model,
      streaming: false,
      onStop: widget.onStop,
      onCopy: () => widget.onCopy(turn.text),
      onRegenerate: widget.onRegenerate,
      onSourceTap: widget.onSourceTap,
      rating: turn.rating,
      onRate: (turn.interactionId != null && widget.onRate != null)
          ? (r) => widget.onRate!(turn, r)
          : null,
    );
  }
}

class _SearchingRow extends StatelessWidget {
  const _SearchingRow();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: c.grey200),
          ),
          child: const AuraMark(size: 15),
        ),
        const SizedBox(width: 8),
        MonoLabel('Aura is reading your notes',
            color: c.grey500, size: 9.5, tracking: 0.16),
        const SizedBox(width: 6),
        _Dots(color: c.grey500),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final Color color;

  const _Dots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 1 - i * 0.3),
              shape: BoxShape.circle,
            ),
          ),
          if (i < 2) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Row(
      children: [
        Expanded(
          child: MonoLabel(message, color: c.chipRed, size: 10, tracking: 0.1),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.grey200),
            ),
            child: Text('Retry',
                style: t.bodySm.copyWith(color: c.grey600, height: 1.0)),
          ),
        ),
      ],
    );
  }
}
