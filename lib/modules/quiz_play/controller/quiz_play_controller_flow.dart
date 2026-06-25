part of 'quiz_play_controller.dart';

/// Per-question intents, the optional countdown, server submission, and the slide
/// advance. Grading is server-authoritative — this layer only reports intent.
extension QuizPlayControllerFlow on QuizPlayController {
  String get questionAttemptId => current?.questionAttemptId ?? '';

  // --- MCQ ---
  void onSelectOption(int index) {
    if (submitting.value) return;
    RecallHaptics.selection();
    selectedIndex.value = index;
  }

  // --- Flashcard ---
  Future<void> onReveal() async {
    if (submitting.value || revealed.value) return;
    submitting.value = true;
    inlineMessage.value = '';
    try {
      final result = await _quizRepo.submitAnswer(
        attemptId: attemptId,
        questionAttemptId: questionAttemptId,
        revealOnly: true,
      );
      flashcardBack.value = result.flashcardBack ?? '';
      revealed.value = true;
      RecallHaptics.selection();
    } on RepoException catch (e) {
      inlineMessage.value = e.message;
    } finally {
      submitting.value = false;
    }
  }

  void onSelfRate(ReviewGrade grade) {
    if (submitting.value) return;
    RecallHaptics.light();
    _submitCurrent(flashcardGrade: grade);
  }

  // --- MCQ / short submit ---
  void onSubmit() {
    if (!canSubmit) return;
    if (isMcq) {
      _submitCurrent(selectedIndex: selectedIndex.value);
    } else if (isShort) {
      _submitCurrent(userAnswer: answerController.text.trim());
    }
  }

  /// Skip = a lapse with no answer stored (server grades `again`).
  void onSkip() {
    if (submitting.value) return;
    RecallHaptics.selection();
    if (isMcq) {
      _submitCurrent(selectedIndex: null);
    } else if (isShort) {
      _submitCurrent(userAnswer: '');
    } else {
      _submitCurrent(flashcardGrade: ReviewGrade.again);
    }
  }

  Future<void> onEnd() async {
    _ticker?.cancel();
    try {
      await _quizRepo.updateAttempt(attemptId, {'status': 'abandoned'});
    } catch (_) {
      // Best-effort; leave navigation unblocked.
    }
    Get.offAllNamed(Routes.quiz);
  }

  Future<void> _submitCurrent({
    int? selectedIndex,
    String? userAnswer,
    ReviewGrade? flashcardGrade,
    bool timedOut = false,
  }) async {
    if (submitting.value) return;
    submitting.value = true;
    inlineMessage.value = '';

    final responseMs = _shownAt == null
        ? null
        : DateTime.now().difference(_shownAt!).inMilliseconds;

    try {
      await _quizRepo.submitAnswer(
        attemptId: attemptId,
        questionAttemptId: questionAttemptId,
        selectedIndex: selectedIndex,
        userAnswer: userAnswer,
        flashcardGrade: flashcardGrade,
        responseMs: responseMs,
        timedOut: timedOut,
      );
      _track('quiz_question_answered');
      submitting.value = false;
      _advance();
    } on RepoException catch (e) {
      submitting.value = false;
      if (e.code == RepoErrorCode.premiumRequired) {
        Get.offAllNamed(Routes.paywall);
        return;
      }
      // Keep local answer; let the user retry the submit.
      inlineMessage.value = '${e.message} Tap to retry.';
    }
  }

  void _advance() {
    _ticker?.cancel();
    final next = currentIndex.value + 1;
    if (next >= total) {
      _finish();
      return;
    }
    currentIndex.value = next;
    _startQuestion();
  }

  void _finish() {
    _ticker?.cancel();
    Get.offNamed(Routes.quizResults, arguments: {'attempt_id': attemptId});
  }

  // --- Countdown ---
  void _startQuestion() {
    _ticker?.cancel();
    timerWarning.value = false;
    selectedIndex.value = null;
    revealed.value = false;
    flashcardBack.value = null;
    inlineMessage.value = '';
    answerController.clear();
    charCount.value = 0;
    _shownAt = DateTime.now();

    if (!hasTimer) {
      remainingSec.value = 0;
      return;
    }
    remainingSec.value = timerSec!;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final next = remainingSec.value - 1;
    remainingSec.value = next;
    if (next == kQuizTimerWarnAt) {
      timerWarning.value = true;
      RecallHaptics.selection();
    }
    if (next <= 0) {
      _ticker?.cancel();
      if (!submitting.value) _submitCurrent(timedOut: true);
    }
  }
}
