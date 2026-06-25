import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/stack_repository.dart';
import '../../../data/repositories/today_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';
import '../../../core/widgets/recall_scaffold.dart';

class TodayController extends BaseController with GetTickerProviderStateMixin {
  final _auth = Get.find<AuthService>();
  final _profileRepo = Get.find<ProfileRepository>();
  final _todayRepo = Get.find<TodayRepository>();
  final _stackRepo = Get.find<StackRepository>();
  final _tierService = Get.find<TierService>();
  final _syncStatus = Get.find<SyncStatusService>();

  final Rxn<Profile> profile = Rxn<Profile>();
  final RxInt dueCount = 0.obs;
  final RxDouble aggregateHeat = 0.0.obs;
  final RxInt hotCount = 0.obs;
  final RxInt warmCount = 0.obs;
  final RxInt coolCount = 0.obs;
  final RxList<DuePreviewNode> peekingNodes = <DuePreviewNode>[].obs;
  final RxInt stacksUsed = 0.obs;
  final RxBool isStarting = false.obs;

  int get currentStreak => profile.value?.currentStreak ?? 0;

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

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _loadData();

    final shell = Get.find<ShellController>();
    ever(shell.currentTab, (RecallTab tab) {
      if (tab == RecallTab.today) {
        reload();
      }
    });
  }

  void _initAnimations() {
    ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
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

      _syncStatus.setOffline(false);
      setSuccess();
      if (dueCount.value > 0) _runAnimations();
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError('You\'re offline. Check your connection and try again.');
      } else {
        setError(e.message);
      }
    }
  }

  void _runAnimations() {
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return;

    ringController.forward(from: 0);
    cardController.forward(from: 0);
  }

  Future<void> reload() async {
    ringController.reset();
    cardController.reset();
    await _loadData();
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

  @override
  void onClose() {
    ringController.dispose();
    cardController.dispose();
    super.onClose();
  }
}
