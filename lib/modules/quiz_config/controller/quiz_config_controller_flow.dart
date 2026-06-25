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
        return 'Tell us the topic in your own words. Be as loose as you like.';
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
    return 'Claude - ~ 4 sec';
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
          bucketIds: selectedBucketIds.toList(),
          nodeIds: selectedNodeIds.toList(),
          prompt: promptController.text.trim(),
          useMyNotes: useMyNotes.value,
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
