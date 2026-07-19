import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/neo_chip.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../quiz_home/view/widgets/quiz_in_progress_sheet.dart';

part 'quiz_play_controller_flow.dart';

/// Short-answer character cap (design: roomy Fraunces textarea, max 280).
const int kQuizShortAnswerMax = 280;

/// Seconds remaining at which the timer pulses + softens to amber-ink.
const int kQuizTimerWarnAt = 10;

class QuizPlayController extends BaseController {
  QuizPlayController(this._auth, this._quizRepo);

  final AuthService _auth;
  final QuizRepository _quizRepo;

  String attemptId = '';
  int? timerSec;
  final RxList<GeneratedQuizQuestion> questions = <GeneratedQuizQuestion>[].obs;

  final RxInt currentIndex = 0.obs;
  final Rxn<int> selectedIndex = Rxn<int>();
  final answerController = TextEditingController();
  final RxInt charCount = 0.obs;
  final RxBool revealed = false.obs;
  final RxnString flashcardBack = RxnString();
  final RxBool submitting = false.obs;
  final RxString inlineMessage = ''.obs;

  // Per-question countdown (only when timerSec is set).
  final RxInt remainingSec = 0.obs;
  final RxBool timerWarning = false.obs;
  Timer? _ticker;
  DateTime? _shownAt;

  int get total => questions.length;
  int get displayPosition => currentIndex.value + 1;
  double get progress => total == 0 ? 0 : displayPosition / total;
  bool get hasTimer => (timerSec ?? 0) > 0;

  GeneratedQuizQuestion? get current =>
      currentIndex.value < questions.length ? questions[currentIndex.value] : null;
  QuizQuestion? get question => current?.question;
  QuizQuestionType get type => question?.type ?? QuizQuestionType.mcq;

  bool get isMcq => type == QuizQuestionType.mcq;
  bool get isShort => type == QuizQuestionType.shortAnswer;
  bool get isFlashcard => type == QuizQuestionType.flashcard;

  /// Top-bar eyebrow: "{bucket} · {type}" (or just the type for free-hand).
  String get eyebrow {
    final bucket = question?.bucketName;
    if (bucket == null || bucket.isEmpty) return typeLabel;
    return '$bucket · $typeLabel';
  }

  String get typeLabel {
    switch (type) {
      case QuizQuestionType.mcq:
        return 'MCQ';
      case QuizQuestionType.shortAnswer:
        return 'SHORT';
      case QuizQuestionType.flashcard:
        return 'FLASHCARD';
      case QuizQuestionType.mix:
        return 'MIX';
    }
  }

  /// Difficulty 1/2 -> EASY, 3 -> MED, 4/5 -> HARD [D-QUIZ-3].
  NeoLevel? get difficultyLevel {
    final d = question?.difficulty;
    if (d == null) return null;
    if (d >= 4) return NeoLevel.high;
    if (d == 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  String get difficultyLabel {
    switch (difficultyLevel) {
      case NeoLevel.high:
        return 'HARD';
      case NeoLevel.medium:
        return 'MED';
      case NeoLevel.low:
        return 'EASY';
      case null:
        return '';
    }
  }

  bool get canSubmit {
    if (submitting.value) return false;
    if (isMcq) return selectedIndex.value != null;
    if (isShort) return answerController.text.trim().isNotEmpty;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(() {
      charCount.value = answerController.text.characters.length;
    });
    _hydrate();
  }

  void _hydrate() {
    final args = Get.arguments;
    if (args is! Map) {
      Get.offAllNamed(Routes.quiz);
      return;
    }

    final generation = QuizGeneration.fromJson(
      args.map((k, v) => MapEntry(k.toString(), v)),
    );
    attemptId = generation.attemptId;
    timerSec = generation.timerSec;
    questions.assignAll(generation.questions);

    if (attemptId.isEmpty || questions.isEmpty) {
      Get.offAllNamed(Routes.quiz);
      return;
    }

    final firstUnanswered = questions.indexWhere((q) => !q.answered);
    if (firstUnanswered == -1) {
      _finish();
      return;
    }

    currentIndex.value = firstUnanswered;
    setSuccess();
    _startQuestion();
  }

  void _track(String event) {
    if (!_auth.analyticsOptIn) return;
    debugPrint('analytics:$event');
  }

  @override
  void onClose() {
    _ticker?.cancel();
    answerController.dispose();
    super.onClose();
  }
}
