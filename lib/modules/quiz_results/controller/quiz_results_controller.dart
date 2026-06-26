import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Node;
import 'package:share_plus/share_plus.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../view/widgets/quiz_feedback_sheet.dart';

/// Score at/above which the calm celebration (haptic + confetti puff) fires.
const int kQuizCelebrationThreshold = 80;

class QuizResultsController extends BaseController {
  QuizResultsController(this._auth, this._quizRepo);

  final AuthService _auth;
  final QuizRepository _quizRepo;
  final AiRepository _aiRepo = Get.find<AiRepository>();

  String attemptId = '';
  final Rx<QuizResult> result = QuizResult().obs;
  final RxBool buildingStack = false.obs;

  /// Hides the post-quiz feedback card once the user has answered (or skipped).
  final RxBool quizFeedbackGiven = false.obs;

  QuizResult get data => result.value;
  int get scoreInt => data.scorePct.round();
  bool get celebrate => scoreInt >= kQuizCelebrationThreshold;
  bool get hasReviewMissed => data.reviewMissedNodeIds.isNotEmpty;

  /// Header eyebrow: "{BUCKET} · RESULTS" — bucket from the attempt scope.
  String get header {
    final scope = data.scopeLabel;
    if (scope == null || scope.isEmpty) return 'RESULTS';
    return '$scope · RESULTS';
  }

  /// Fraunces headline softens as the score drops (design §edge cases).
  String get headline {
    if (scoreInt >= 100) return 'Locked in.';
    if (scoreInt >= kQuizCelebrationThreshold) return 'That one stuck.';
    if (scoreInt >= 50) return 'Plenty to revisit.';
    return 'Worth another pass.';
  }

  /// One quiet supporting line; never a "fail", never red.
  String get caption {
    if (celebrate) return 'Your strongest answers held. Nicely done.';
    return "We've moved the shaky ones sooner in the queue — no pressure.";
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    attemptId = (args is Map ? args['attempt_id']?.toString() : null) ?? '';
    if (attemptId.isEmpty) {
      Get.offAllNamed(Routes.quiz);
      return;
    }
    _hydrate();
  }

  Future<void> _hydrate() async {
    setLoading();
    try {
      final res = await _quizRepo.complete(attemptId);
      result.value = res;
      setSuccess();
      _afterLoad(res);
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.premiumRequired) {
        Get.offAllNamed(Routes.paywall);
        return;
      }
      setError(e.message);
    }
  }

  void _afterLoad(QuizResult res) {
    _track('quiz_completed');
    if (res.xpAwarded > 0) {
      Get.snackbar(
        '+${res.xpAwarded} XP',
        'Saved to your profile.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
    // Celebration haptic only on a high score, after the ring has mostly drawn.
    if (celebrate) {
      Future.delayed(const Duration(milliseconds: 600), RecallHaptics.medium);
    }
  }

  Future<void> retry() => _hydrate();

  Future<void> onShare() async {
    final score = scoreInt;
    final scope = data.scopeLabel;
    final where = (scope == null || scope.isEmpty) ? 'quiz' : '$scope quiz';
    final text = 'I scored $score% on my $where in Recall — '
        '${data.correct}/${data.total} correct. Forget forgetting.';
    try {
      await Share.share(text);
    } catch (_) {
      // Share is best-effort; a dismissed sheet is not an error.
    }
  }

  Future<void> onReviewMissed() async {
    if (buildingStack.value || !hasReviewMissed) return;
    buildingStack.value = true;
    RecallHaptics.selection();
    try {
      final payload = await _quizRepo.buildMissedStack(data.reviewMissedNodeIds);
      final hasStack = payload['stack'] != null;
      if (!hasStack) {
        buildingStack.value = false;
        return;
      }
      _track('review_missed_started');
      Get.offNamed(Routes.review);
    } on RepoException catch (_) {
      buildingStack.value = false;
    }
  }

  /// Opt-in post-quiz feedback → per-user quiz calibration [D-AI-8].
  void openQuizFeedback() {
    RecallHaptics.selection();
    QuizFeedbackSheet.show(
      onSubmit: submitQuizFeedback,
      onSkip: () => quizFeedbackGiven.value = true,
    );
  }

  Future<void> submitQuizFeedback(
    bool helpful,
    int difficulty,
    String text,
  ) async {
    quizFeedbackGiven.value = true;
    final parts = <String>[];
    if (difficulty < 0) parts.add('make quizzes a bit harder');
    if (difficulty > 0) parts.add('make quizzes a bit easier');
    if (!helpful) parts.add('that quiz did not feel very helpful');
    if (text.trim().isNotEmpty) parts.add(text.trim());
    final suggestion = parts.join('; ');
    if (suggestion.isEmpty) return;
    await _aiRepo.submitSuggestion(suggestion, rating: helpful ? 1 : -1);
  }

  void onWeakTopicTap(String nodeId) {
    RecallHaptics.selection();
    Get.toNamed(Routes.node, arguments: {'node_id': nodeId});
  }

  void onDone() {
    RecallHaptics.selection();
    Get.offAllNamed(Routes.quiz);
  }

  void _track(String event) {
    if (!_auth.analyticsOptIn) return;
    debugPrint('analytics:$event');
  }
}
