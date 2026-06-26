import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';

class QuizHomeController extends BaseController
    with GetTickerProviderStateMixin {
  QuizHomeController(
    this._auth,
    this._quizRepo,
    this._tierService,
  );

  final AuthService _auth;
  final QuizRepository _quizRepo;
  final TierService _tierService;
  final _metrics = Get.find<MetricsService>();

  final RxList<QuizAttempt> recentAttempts = <QuizAttempt>[].obs;
  final Rxn<QuizAttempt> resumable = Rxn<QuizAttempt>();
  final RxBool resuming = false.obs;
  late final AnimationController staggerController;
  Worker? _tabWorker;

  TierGate get gate => _tierService.gate;
  bool get locked => gate.quizBlocked;
  bool get isPremium => gate.isPremium;

  /// Read inside [Obx] so GetX tracks [TierService.tierRx].
  bool get isPremiumRx => _tierService.tierRx.value == SubscriptionTier.premium;

  @override
  void onInit() {
    super.onInit();
    staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _load();

    final shell = Get.find<ShellController>();
    _tabWorker = ever(shell.currentTab, (RecallTab tab) {
      if (isClosed) return;
      if (tab == RecallTab.quiz) reload();
    });
  }

  Future<void> reload() async {
    if (isClosed) return;
    staggerController.reset();
    await _load();
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    try {
      final results = await Future.wait([
        _quizRepo.fetchRecentAttempts(userId, limit: 8),
        _quizRepo.fetchInProgressAttempt(userId),
      ]);

      recentAttempts.assignAll(results[0] as List<QuizAttempt>);
      resumable.value = results[1] as QuizAttempt?;

      setSuccess();
      _runStagger();
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  void _runStagger() {
    if (isClosed) return;
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      staggerController.value = 1;
    } else {
      staggerController.forward(from: 0);
    }
  }

  void onModeTap(QuizMode mode) {
    if (locked) {
      RecallHaptics.light();
      _metrics.downgradedGateHit('quiz_home');
      Get.toNamed(Routes.paywall);
      return;
    }

    RecallHaptics.selection();
    Get.toNamed(Routes.quizConfig, arguments: {'mode': mode.wire});
  }

  String get resumeLabel {
    final attempt = resumable.value;
    if (attempt == null) return '';
    final count = attempt.questionCount ?? 0;
    return 'Pick up where you left off · $count Q';
  }

  Future<void> onResume() async {
    final attempt = resumable.value;
    if (attempt == null || resuming.value) return;

    resuming.value = true;
    try {
      final generation = await _quizRepo.resumeAttempt(attempt.id);
      RecallHaptics.selection();
      Get.toNamed(Routes.quizPlay, arguments: generation.toJson());
    } on RepoException catch (e) {
      // Attempt is gone or no longer in progress — clear the entry and refresh.
      if (e.code == RepoErrorCode.invalidInput ||
          e.code == RepoErrorCode.notFound) {
        resumable.value = null;
      }
    } finally {
      resuming.value = false;
    }
  }

  String recentLabel(QuizAttempt attempt) {
    final date = attempt.completedAt ?? attempt.createdAt ?? DateTime.now();
    final month = _months[date.toLocal().month - 1];
    final score = attempt.scorePct == null ? '--' : attempt.scorePct!.round();
    final count = attempt.questionCount ?? 0;
    return '${date.toLocal().day} $month - $count Q - $score%';
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    staggerController.dispose();
    super.onClose();
  }
}

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
