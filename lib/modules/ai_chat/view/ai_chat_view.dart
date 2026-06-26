// Ask Recall — the RAG chat screen. A calm document: the user's question on the
// right, the AI's editorial answer flowing down the page with source chips and a
// model label. All product decisions are backend-authoritative; this view only
// renders controller state and routes intents.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/ai_chat_controller.dart';
import 'widgets/ai_chat_thread.dart';
import 'widgets/ai_chat_top_bar.dart';
import 'widgets/ai_composer.dart';
import 'widgets/ai_locked_composer.dart';
import 'widgets/aura_tune_sheet.dart';

class AiChatView extends GetView<AiChatController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Scaffold(
      backgroundColor: c.canvas,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          Obx(() => AiChatTopBar(
                nodeCount: controller.nodeCount.value,
                onBack: Get.back,
                onMenu: () => AuraTuneSheet.show(controller),
              )),
          Expanded(
            child: Obx(
              () => RecallStateView(
                state: controller.viewState,
                loading:
                    const Center(child: CircularProgressIndicator.adaptive()),
                errorMessage: controller.errorMessage,
                onRetry: controller.retryLast,
                child: const _Thread(),
              ),
            ),
          ),
          const _Footer(),
        ],
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiChatController>();
    return Obx(() => AiChatThread(
          turns: controller.turns.toList(),
          phase: controller.phase.value,
          streamText: controller.streamText.value,
          liveCitations: controller.liveCitations.toList(),
          liveModel: controller.liveModel.value,
          answerError: controller.answerError.value,
          showSuggestions: controller.showSuggestions,
          onStop: controller.stop,
          onRegenerate: controller.regenerate,
          onRetry: controller.retryLast,
          onSuggested: controller.onSuggestedPrompt,
          onCopy: controller.copyAnswer,
          onSourceTap: controller.onSourceTap,
          onRate: controller.rateTurn,
        ));
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiChatController>();
    return Obx(() {
      final reason = controller.composerLockReason;
      if (reason != null) {
        return AiLockedComposer(
          reason: reason,
          showUpgrade: true,
          quotaLabel: controller.freeQuotaLock ? controller.quotaLabel : null,
          onUpgrade: controller.buyCredits,
        );
      }
      return AiComposer(
        controller: controller.composer,
        onSend: controller.send,
        offline: controller.offline.value,
      );
    });
  }
}
