part of 'quiz_config_controller.dart';

extension QuizConfigControllerFlow on QuizConfigController {
  String get modeEyebrow {
    switch (mode.value) {
      case QuizMode.freehand:
        return 'FREE-HAND';
      case QuizMode.byBucket:
        return 'BY BUCKET';
      case QuizMode.byNode:
        return 'BY NODE';
    }
  }

  String get subtitle {
    switch (mode.value) {
      case QuizMode.freehand:
        return 'Tell us a topic. Aura grounds it in your notes, then fills the '
            'gaps with broader knowledge.';
      case QuizMode.byBucket:
        return 'Pick what to draw from, how many, and how hard.';
      case QuizMode.byNode:
        return 'Choose notes to drill into, then set the shape of the round.';
    }
  }

  String get footerHint {
    if (isOffline) return 'AI generation needs a connection.';
    if (!gate.isPremium) return 'Premium required.';
    if (inlineMessage.value.isNotEmpty) return inlineMessage.value;
    return 'Aura · ~4 sec';
  }

  Future<void> generate() async {
    if (!canGenerate) {
      _syncSelectionMessage();
      return;
    }

    final userId = _auth.currentUserId;
    if (userId == null) return;

    generating.value = true;
    inlineMessage.value = '';

    try {
      final config = await _quizRepo.createConfig(
        QuizConfig(
          id: '',
          userId: userId,
          mode: mode.value,
          bucketIds: isByBucket || (isFreehand && useMyNotes.value)
              ? selectedBucketIds.toList()
              : const [],
          nodeIds: isByNode ? selectedNodeIds.toList() : const [],
          prompt: isFreehand ? promptController.text.trim() : null,
          useMyNotes: isFreehand ? useMyNotes.value : true,
          questionCount: questionCount.value,
          questionType: questionType.value,
          difficulty: difficulty.value,
          timerSec: timerEnabled.value ? timerSec.value : null,
        ),
      );

      final generation = await _quizRepo.generate(config.id);
      _track('quiz_started');
      RecallHaptics.medium();
      Get.toNamed(Routes.quizPlay, arguments: generation.toJson());
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.premiumRequired) {
        inlineMessage.value = 'Premium required.';
        Get.toNamed(Routes.paywall);
      } else if (e.code == RepoErrorCode.emptyContext) {
        inlineMessage.value =
            'Your selected notes have no readable content yet. Add text and retry.';
      } else if (e.code == RepoErrorCode.aiCooldown) {
        inlineMessage.value = 'Aura is on a short break. Try again in a bit.';
      } else if (e.code == RepoErrorCode.maintenance ||
          e.code == RepoErrorCode.providerError) {
        inlineMessage.value = '${e.message} Tap Generate to retry.';
      } else {
        inlineMessage.value = e.message;
      }
    } finally {
      generating.value = false;
    }
  }
}
