import 'dart:async';
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/feature.dart';
import '../../../core/utils/coach_keys.dart';
import '../../../core/utils/drop_readiness.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai/ai_repository.dart';
import '../../../data/repositories/bucket/bucket_repository.dart';
import '../../../data/repositories/insights/insights_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/stack/stack_repository.dart';
import '../../../data/repositories/today/today_repository.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/services/billing/tier_service.dart';
import '../../../data/services/metrics/metrics_service.dart';
import '../../../data/services/platform/notification_service.dart';
import '../../../data/services/shared/repo_exception.dart';
import '../../../data/services/sync/sync_status_service.dart';
import '../../shell/controller/shell_controller.dart';

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
  final _local = Get.find<LocalStore>();

  final Rxn<Profile> profile = Rxn<Profile>();
  final RxInt dueCount = 0.obs;
  final RxDouble aggregateHeat = 0.0.obs;
  final RxInt hotCount = 0.obs;
  final RxInt warmCount = 0.obs;
  final RxInt coolCount = 0.obs;
  final RxList<DuePreviewNode> peekingNodes = <DuePreviewNode>[].obs;
  final RxInt stacksUsed = 0.obs;
  final RxBool isStarting = false.obs;

  // Active-stack progress backing the "7/8 Cards" hero. Zero when no stack is
  // in flight — the hero then falls back to what today's session would hold.
  final RxInt _activeTotal = 0.obs;
  final RxInt _activeReviewed = 0.obs;

  /// One-time tip explaining what "due" means (seen via [CoachKeys.todayDue]).
  final RxBool showDueCoachTip = false.obs;

  // Empty / all-caught-up state (S25).
  final RxInt bucketCount = 0.obs;
  final RxInt nodeCount = 0.obs;
  final Rxn<DateTime> nextDropAt = Rxn<DateTime>();
  final Rxn<DoneFastBanner> doneFastBanner = Rxn<DoneFastBanner>();

  // Re-learn weak skills nudge [D-AI-9]. Loaded best-effort; never blocks Today.
  final RxList<RelearnSkill> relearnSkills = <RelearnSkill>[].obs;
  final RxBool relearnDismissed = false.obs;
  final RxBool isRelearnStarting = false.obs;

  bool get showRelearn => relearnSkills.isNotEmpty && !relearnDismissed.value;
  int get relearnCount => relearnSkills.length;

  int get currentStreak => profile.value?.currentStreak ?? 0;

  /// A stack was generated and still has unreviewed cards — resume it instead
  /// of generating a new one.
  bool get hasActiveSession =>
      _activeTotal.value > 0 && _activeReviewed.value < _activeTotal.value;

  int get sessionTotal {
    if (hasActiveSession) return _activeTotal.value;
    final cap = _tierService.gate.cardsPerStack;
    return dueCount.value < cap ? dueCount.value : cap;
  }

  int get cardsRemaining =>
      sessionTotal - (hasActiveSession ? _activeReviewed.value : 0);

  /// Whether a Drop can actually reach this user. Mirrors the backend gate so
  /// the caught-up screen explains an absent next-drop time honestly.
  bool get pushEnabled => profile.value?.pushOptIn ?? false;

  /// Account-wide Cards-before-a-Drop setting (profiles.drop_frequency).
  String get dropFrequency =>
      profile.value?.dropFrequency ?? kDefaultDropFrequency;

  bool get isAllCaughtUp => dueCount.value == 0 && bucketCount.value > 0;
  bool get isNoBuckets => bucketCount.value == 0;
  bool get hasNotes => nodeCount.value > 0;

  String get formattedDate {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[now.weekday - 1]} ${now.day}';
  }

  bool get isFree => !_tierService.gate.isPremium;
  int get stacksCap => _tierService.gate.capFor(Feature.reviewStack);
  bool get isAtStackLimit => !_tierService.gate
      .access(Feature.reviewStack, used: stacksUsed.value)
      .allowed;
  bool get showStacksMeter =>
      !_tierService.gate.suppressPaywall &&
      isFree &&
      _tierService.gate.limits.showStacksMeter;

  void openPaywall() => _tierService.openPaywall();

  /// Resuming a stack is never a new stack, so the monthly cap can't block it.
  String get reviewCtaLabel {
    if (hasActiveSession) return 'Continue review';
    return isAtStackLimit ? 'Unlock unlimited reviews' : 'Start review';
  }

  Future<void> onReviewCta() async {
    if (hasActiveSession) return continueReview();
    if (isAtStackLimit) {
      openPaywall();
      return;
    }
    await startReview();
  }

  static const _cardFanDuration = Duration(milliseconds: 1500);
  static const _cardNestDuration = Duration(milliseconds: 360);
  static const _cardIdleRest = Duration(seconds: 10);

  late final AnimationController cardController;
  Worker? _tabWorker;
  Worker? _sessionWorker;
  Timer? _cardIdleTimer;

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
    cardController = AnimationController(
      vsync: this,
      duration: _cardFanDuration,
    );
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      // Reached before the Supabase session restored (e.g. cold-start from a
      // notification tap). Keep the skeleton up and retry once the session
      // appears so Today never sticks on a permanent grey shimmer.
      _awaitSession();
      return;
    }

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
        _clearActiveSession();
        await _loadCaughtUpExtras();
      } else {
        nextDropAt.value = null;
        doneFastBanner.value = null;
        await _loadActiveSession(userId);
      }

      _syncStatus.setOffline(false);
      setSuccess();
      if (dueCount.value > 0) {
        _runAnimations();
        unawaited(_maybeShowDueCoachTip());
      }
      _loadRelearn();
      _ensurePushPermission();
      unawaited(Get.find<InsightsRepository>().prefetchDashboard());
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError('You\'re offline. Check your connection and try again.');
      } else {
        setError(e.message);
      }
    } catch (_) {
      // Any non-RepoException must not leave Today stuck on the skeleton —
      // surface the retry card instead of a frozen grey screen.
      setError('Something went wrong. Pull to retry.');
    }
  }

  /// One-shot: re-run the load as soon as a session appears. Guards the
  /// cold-start window where Today builds before Supabase restores the session.
  void _awaitSession() {
    _sessionWorker?.dispose();
    _sessionWorker = ever(_auth.sessionRx, (session) {
      if (isClosed || session == null) return;
      _sessionWorker?.dispose();
      _sessionWorker = null;
      _loadData();
    });
  }

  /// Best-effort: the hero falls back to the session-size view if the active
  /// stack can't be read, so a failure here must never break Today.
  Future<void> _loadActiveSession(String userId) async {
    try {
      final stack = await _stackRepo.fetchActive(userId);
      if (stack == null || stack.status != StackStatus.active) {
        _clearActiveSession();
        return;
      }
      final items = await _stackRepo.fetchItems(stack.id);
      _activeTotal.value = items.length;
      _activeReviewed.value = items.where((i) => i.reviewed).length;
    } catch (_) {
      _clearActiveSession();
    }
  }

  void _clearActiveSession() {
    _activeTotal.value = 0;
    _activeReviewed.value = 0;
  }

  Future<void> _loadCaughtUpExtras() async {
    try {
      final results = await Future.wait([
        _bucketRepo.fetchGlobalNextDrop(),
        _metrics.consumeDoneFastBanner(),
      ]);
      nextDropAt.value = results[0] as DateTime?;
      doneFastBanner.value = results[1] as DoneFastBanner?;
    } on RepoException catch (_) {
      // Non-critical; empty state renders without next-drop extras.
    }
  }

  Future<void> _maybeShowDueCoachTip() async {
    if (await _local.coachSeen(CoachKeys.todayDue)) return;
    if (isClosed) return;
    showDueCoachTip.value = true;
  }

  Future<void> dismissDueCoachTip() async {
    if (!showDueCoachTip.value) return;
    showDueCoachTip.value = false;
    await _local.markCoachSeen(CoachKeys.todayDue);
  }

  void _runAnimations() {
    _cancelCardIdleLoop();
    if (isClosed) return;
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      cardController.value = 1.0;
      return;
    }

    unawaited(_playCardFanThenScheduleIdle(fromZero: true));
  }

  /// Fan the peeking stack in, then rest 10s and gently nest → re-fan on loop.
  Future<void> _playCardFanThenScheduleIdle({bool fromZero = false}) async {
    if (isClosed || dueCount.value == 0) return;
    cardController.duration = _cardFanDuration;
    try {
      await cardController.forward(from: fromZero ? 0 : null);
    } catch (_) {
      return;
    }
    if (isClosed || dueCount.value == 0) return;
    _scheduleCardIdleCycle();
  }

  void _scheduleCardIdleCycle() {
    _cancelCardIdleLoop();
    if (isClosed || dueCount.value == 0) return;
    if (PlatformDispatcher.instance.accessibilityFeatures.disableAnimations) {
      return;
    }

    _cardIdleTimer = Timer(_cardIdleRest, () {
      unawaited(_runCardIdleCycle());
    });
  }

  Future<void> _runCardIdleCycle() async {
    if (isClosed || dueCount.value == 0) return;
    if (PlatformDispatcher.instance.accessibilityFeatures.disableAnimations) {
      cardController.value = 1.0;
      return;
    }

    // Soft nest — calm ease, short duration — then bubbly re-fan.
    cardController.duration = _cardNestDuration;
    try {
      await cardController.reverse();
    } catch (_) {
      return;
    }
    if (isClosed || dueCount.value == 0) return;

    await _playCardFanThenScheduleIdle();
  }

  void _cancelCardIdleLoop() {
    _cardIdleTimer?.cancel();
    _cardIdleTimer = null;
  }

  Future<void> reload() async {
    if (isClosed) return;
    _cancelCardIdleLoop();
    cardController.duration = _cardFanDuration;
    cardController.reset();
    await _loadData();
  }

  /// Updates Reminder style from the Today caught-up explainer, then refreshes
  /// the next-cards ETA so the clock matches the new intensity.
  Future<void> setDropFrequency(String value) async {
    if (value == dropFrequency) return;
    final prev = profile.value;
    if (prev == null) return;
    RecallHaptics.selection();
    profile.value = prev.copyWith(dropFrequency: value);
    try {
      profile.value = await _profileRepo.updatePreferences(
        prev.id,
        {'drop_frequency': value},
      );
      if (dueCount.value == 0 && bucketCount.value > 0) {
        await _loadCaughtUpExtras();
      }
    } on RepoException {
      profile.value = prev;
    }
  }

  bool _pushEnsured = false;

  /// Catch-all for users who skipped onboarding (e.g. reinstall with an account
  /// that already finished it): if they want drops but the OS grant is missing,
  /// re-request it once. Opted-out users are left alone.
  void _ensurePushPermission() {
    if (_pushEnsured) return;
    _pushEnsured = true;
    if (profile.value?.pushOptIn != true) return;
    unawaited(Get.find<NotificationService>().ensurePermissionAndToken());
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

  /// Resumes the stack already in flight — no `generate`, so the cards and
  /// their order stay exactly where the user left them.
  Future<void> continueReview() async {
    if (isStarting.value) return;
    isStarting.value = true;
    unawaited(dismissDueCoachTip());

    try {
      RecallHaptics.light();
      await Get.toNamed(Routes.review);
      await reload();
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> startReview() async {
    if (isStarting.value) return;
    isStarting.value = true;
    unawaited(dismissDueCoachTip());

    try {
      RecallHaptics.light();
      final result = await _stackRepo.generate();

      if (result.stack != null) {
        // Review pops back to this shell; refresh Today so streak/due counts
        // update without needing a tab leave/re-enter.
        await Get.toNamed(Routes.review);
        await reload();
      } else if (result.reason == 'empty_pool' ||
          result.reason == 'empty_scope') {
        await reload();
      }
    } on RepoException catch (e) {
      if (e.code == RepoErrorCode.freeTierStackLimit) {
        _tierService.enforce(Feature.reviewStack, used: stacksUsed.value);
      } else {
        setError(e.message);
      }
    } finally {
      isStarting.value = false;
    }
  }

  void openQuiz() {
    Get.find<ShellController>().onTabSelected(RecallTab.quiz);
  }

  void onAddNote() {
    RecallHaptics.selection();
    Get.toNamed(Routes.nodeAdd);
  }

  void onMakeBucket() {
    RecallHaptics.light();
    Get.toNamed(Routes.nodeAdd);
  }

  @override
  void onClose() {
    _cancelCardIdleLoop();
    _tabWorker?.dispose();
    _sessionWorker?.dispose();
    cardController.dispose();
    super.onClose();
  }
}
