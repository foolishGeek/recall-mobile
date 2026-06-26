import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/stack_repository.dart';
import '../../../data/repositories/today_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';
import '../../../core/widgets/recall_scaffold.dart';

class TodayController extends BaseController with GetTickerProviderStateMixin {
  final _auth = Get.find<AuthService>();
  final _profileRepo = Get.find<ProfileRepository>();
  final _todayRepo = Get.find<TodayRepository>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _stackRepo = Get.find<StackRepository>();
  final _aiRepo = Get.find<AiRepository>();
  final _tierService = Get.find<TierService>();
  final _syncStatus = Get.find<SyncStatusService>();
  final _metrics = Get.find<MetricsService>();

  final Rxn<Profile> profile = Rxn<Profile>();
  final RxInt dueCount = 0.obs;
  final RxDouble aggregateHeat = 0.0.obs;
  final RxInt hotCount = 0.obs;
  final RxInt warmCount = 0.obs;
  final RxInt coolCount = 0.obs;
  final RxList<DuePreviewNode> peekingNodes = <DuePreviewNode>[].obs;
  final RxInt stacksUsed = 0.obs;
  final RxBool isStarting = false.obs;

  // Empty / all-caught-up state (S25).
  final RxInt bucketCount = 0.obs;
  final RxInt nodeCount = 0.obs;
  final Rxn<DateTime> nextDropAt = Rxn<DateTime>();
  final RxBool showReviewAhead = false.obs;
  final RxBool isStartingAhead = false.obs;
  final Rxn<DoneFastBanner> doneFastBanner = Rxn<DoneFastBanner>();

  // Re-learn weak skills nudge [D-AI-9]. Loaded best-effort; never blocks Today.
  final RxList<RelearnSkill> relearnSkills = <RelearnSkill>[].obs;
  final RxBool relearnDismissed = false.obs;
  final RxBool isRelearnStarting = false.obs;

  bool get showRelearn =>
      relearnSkills.isNotEmpty && !relearnDismissed.value;
  int get relearnCount => relearnSkills.length;

  int get currentStreak => profile.value?.currentStreak ?? 0;

  bool get isAllCaughtUp => dueCount.value == 0 && bucketCount.value > 0;
  bool get isNoBuckets => bucketCount.value == 0;
  bool get hasNotes => nodeCount.value > 0;

  String get formattedDate {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[now.weekday - 1]} ${now.day}';
  }

  bool get isFree => !_tierService.gate.isPremium;
  bool get isAtStackLimit => isFree && stacksUsed.value >= 2;

  late final AnimationController ringController;
  late final AnimationController cardController;
  late final Animation<double> ringProgress;
  late final Animation<double> haloOpacity;
  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _loadData();

    final shell = Get.find<ShellController>();
    _tabWorker = ever(shell.currentTab, (RecallTab tab) {
      if (isClosed) return;
      if (tab == RecallTab.today) reload();
    });
  }

  void _initAnimations() {
    ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    ringProgress = CurvedAnimation(
      parent: ringController,
      curve: Curves.easeInOut,
    );
    haloOpacity = CurvedAnimation(
      parent: ringController,
      curve: const Interval(0.74, 1.0),
    );
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();

    try {
      final results = await Future.wait([
        _profileRepo.fetchProfile(userId),
        _todayRepo.fetchTodaySummary(),
        _todayRepo.fetchDuePoolPreview(),
        _profileRepo.fetchStacksCreatedThisMonth(userId),
        _bucketRepo.fetchAll(userId),
        _bucketRepo.fetchTotalNodeCount(userId),
      ]);

      profile.value = results[0] as Profile?;
      final summary = results[1] as TodaySummary;
      dueCount.value = summary.dueCount;
      aggregateHeat.value = summary.aggregateHeat;
      hotCount.value = summary.hotCount;
      warmCount.value = summary.warmCount;
      coolCount.value = summary.coolCount;
      peekingNodes.assignAll(results[2] as List<DuePreviewNode>);
      stacksUsed.value = results[3] as int;
      bucketCount.value = (results[4] as List<Bucket>).length;
      nodeCount.value = results[5] as int;

      if (dueCount.value == 0 && bucketCount.value > 0) {
        await _loadCaughtUpExtras();
      } else {
        nextDropAt.value = null;
        showReviewAhead.value = false;
        doneFastBanner.value = null;
      }

      _syncStatus.setOffline(false);
      setSuccess();
      if (dueCount.value > 0) _runAnimations();
      _loadRelearn();
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError('You\'re offline. Check your connection and try again.');
      } else {
        setError(e.message);
      }
    }
  }

  Future<void> _loadCaughtUpExtras() async {
    try {
      final results = await Future.wait([
        _bucketRepo.fetchGlobalNextDrop(),
        _todayRepo.fetchReviewAheadCount(),
        _metrics.consumeDoneFastBanner(),
      ]);
      nextDropAt.value = results[0] as DateTime?;
      showReviewAhead.value = (results[1] as int) > 0;
      doneFastBanner.value = results[2] as DoneFastBanner?;
    } on RepoException catch (_) {
      // Non-critical; empty state renders without next-drop / review-ahead.
    }
  }

  void _runAnimations() {
    if (isClosed) return;
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      ringController.value = 1.0;
      cardController.value = 1.0;
      return;
    }

    ringController.forward(from: 0);
    cardController.forward(from: 0);
  }

  Future<void> reload() async {
    if (isClosed) return;
    ringController.reset();
    cardController.reset();
    await _loadData();
  }

  Future<void> _loadRelearn() async {
    try {
      final skills = await _aiRepo.fetchRelearnSkills(limit: 12);
      relearnSkills.assignAll(skills);
    } catch (_) {
      relearnSkills.clear();
    }
  }

  void dismissRelearn() {
    RecallHaptics.light();
    relearnDismissed.value = true;
  }

  Future<void> startRelearn() async {
    if (isRelearnStarting.value) return;
    isRelearnStarting.value = true;
    try {
      RecallHaptics.medium();
      final nodeIds = await _aiRepo.buildRelearnSession(limit: 20);
      if (nodeIds.isEmpty) {
        relearnSkills.clear();
        return;
      }
      Get.toNamed(Routes.quizConfig, arguments: {
        'mode': 'by_node',
        'node_ids': nodeIds,
      });
    } on RepoException catch (e) {
      setError(e.message);
    } finally {
      isRelearnStarting.value = false;
    }
  }

  Future<void> startReview() async {
    if (isStarting.value) return;
    isStarting.value = true;

    try {
      RecallHaptics.light();
      final result = await _stackRepo.generate();

      if (result.stack != null) {
        Get.toNamed(Routes.review);
      } else if (result.reason == 'empty_pool' ||
          result.reason == 'empty_scope') {
        await reload();
      }
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.freeTierStackLimit) {
        Get.toNamed(Routes.paywall);
      } else {
        setError(e.message);
      }
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> startReviewAhead() async {
    if (isStartingAhead.value) return;
    isStartingAhead.value = true;

    try {
      RecallHaptics.light();
      final result = await _stackRepo.generate(ahead: true);

      if (result.stack != null) {
        Get.toNamed(Routes.review);
      } else {
        showReviewAhead.value = false;
        Get.snackbar(
          'Nothing to review ahead',
          'All upcoming cards are still resting.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.freeTierStackLimit) {
        Get.toNamed(Routes.paywall);
      } else {
        setError(e.message);
      }
    } finally {
      isStartingAhead.value = false;
    }
  }

  void onMakeBucket() {
    RecallHaptics.light();
    Get.toNamed(Routes.nodeAdd);
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    ringController.dispose();
    cardController.dispose();
    super.onClose();
  }
}
