import 'dart:async';
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/coach_keys.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/utils/recall_time.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../shell/controller/shell_controller.dart';

enum BucketFilter { all, active, cooling, aToZ }

class BucketsController extends BaseController
    with GetTickerProviderStateMixin {
  final _auth = Get.find<AuthService>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _tierService = Get.find<TierService>();
  final _syncStatus = Get.find<SyncStatusService>();
  final _metrics = Get.find<MetricsService>();
  final _local = Get.find<LocalStore>();

  final RxList<Bucket> buckets = <Bucket>[].obs;
  final RxSet<String> activeBucketIds = <String>{}.obs;
  final RxInt bucketCount = 0.obs;
  final RxInt nodeCount = 0.obs;
  final RxMap<String, BucketHeatStats> heatStats =
      <String, BucketHeatStats>{}.obs;
  final RxMap<String, double> masteryMap = <String, double>{}.obs;
  final RxMap<String, DateTime> nextDropMap = <String, DateTime>{}.obs;
  final RxString searchQuery = ''.obs;
  final Rx<BucketFilter> activeFilter = BucketFilter.all.obs;
  final RxBool isSearchVisible = false.obs;

  /// One-time tip on buckets + skip-revision (seen via [CoachKeys.bucketsRevision]).
  final RxBool showRevisionCoachTip = false.obs;

  late final AnimationController staggerController;
  Worker? _tabWorker;

  bool get hasBuckets => buckets.isNotEmpty;

  List<Bucket> get filteredBuckets {
    var list = buckets.toList();

    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((b) => b.name.toLowerCase().contains(q)).toList();
    }

    switch (activeFilter.value) {
      case BucketFilter.all:
        break;
      case BucketFilter.active:
        list = list.where((b) => !isCooling(b)).toList();
      case BucketFilter.cooling:
        list = list.where((b) => isCooling(b)).toList();
      case BucketFilter.aToZ:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  bool get fabLocked {
    _tierService.tierRx.value;
    return _tierService.gate
        .showBucketFabLock(currentBucketCount: buckets.length);
  }

  bool isReadOnly(Bucket b) =>
      _tierService.gate.isDowngraded && !activeBucketIds.contains(b.id);

  bool isCooling(Bucket b) =>
      b.cooldownUntil != null && b.cooldownUntil!.isAfter(DateTime.now());

  double masteryFor(Bucket b) {
    final hs = b.heatSummary;
    if (hs.masteryProgress > 0) return hs.masteryProgress;
    final fromView = masteryMap[b.id];
    if (fromView != null) return (fromView / 100.0).clamp(0.0, 1.0);
    return 0.0;
  }

  double heatFor(Bucket b) {
    final hs = b.heatSummary;
    if (hs.aggregateHeat > 0) return hs.aggregateHeat;
    return 0.0;
  }

  int dominantPriorityFor(Bucket b) {
    final hs = b.heatSummary;
    if (hs.dominantPriority > 1) return hs.dominantPriority;
    return heatStats[b.id]?.dominantPriority ?? 1;
  }

  int nodeCountFor(Bucket b) => heatStats[b.id]?.nodeCount ?? 0;

  bool isActive(Bucket b) => !isCooling(b);

  // The human "next Recall drop" value shown under the NEXT DROP micro-label.
  // Always relative + dated so it reads with context (never a bare "02:00").
  String nextDropValue(Bucket b) {
    final dt = nextDropMap[b.id] ?? (isCooling(b) ? b.cooldownUntil : null);
    if (dt == null) return 'Scheduling…';

    final now = DateTime.now();
    final local = dt.toLocal();
    if (!local.isAfter(now)) return 'Ready now';

    final diff = local.difference(now);
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    if (diff.inHours < 12) return 'In ${diff.inHours}h';

    final today = DateTime(now.year, now.month, now.day);
    final dropDay = DateTime(local.year, local.month, local.day);
    final dayDiff = dropDay.difference(today).inDays;
    if (dayDiff <= 0) {
      return 'Today · ${RecallTime.clock12h(local)}';
    }
    if (dayDiff == 1) return 'Tomorrow';
    if (dayDiff < 7) return 'In $dayDiff days';
    if (dayDiff < 14) return 'Next week';
    return 'In ${(dayDiff / 7).round()}w';
  }

  @override
  void onInit() {
    super.onInit();
    staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadData();

    final shell = Get.find<ShellController>();
    _tabWorker = ever(shell.currentTab, (RecallTab tab) {
      if (isClosed) return;
      if (tab == RecallTab.buckets) reload();
    });
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();

    try {
      final results = await Future.wait([
        _bucketRepo.fetchAll(userId),
        _bucketRepo.fetchActiveBuckets(userId),
        _bucketRepo.fetchAllHeatStats(userId),
        _bucketRepo.fetchAllMastery(userId),
        _bucketRepo.fetchTotalNodeCount(userId),
      ]);

      final loadedBuckets = results[0] as List<Bucket>;
      final activeBuckets = results[1] as List<Bucket>;

      buckets.assignAll(loadedBuckets);
      activeBucketIds
        ..clear()
        ..addAll(activeBuckets.map((b) => b.id));
      bucketCount.value = loadedBuckets.length;
      heatStats.assignAll(results[2] as Map<String, BucketHeatStats>);
      masteryMap.assignAll(results[3] as Map<String, double>);
      nodeCount.value = results[4] as int;

      _syncStatus.setOffline(false);
      setSuccess();
      _runStagger();
      unawaited(_maybeShowRevisionCoachTip());

      _loadNextDropTimes(loadedBuckets);
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError('You\'re offline. Check your connection and try again.');
      } else {
        setError(e.message);
      }
    }
  }

  Future<void> _maybeShowRevisionCoachTip() async {
    if (buckets.isEmpty) return;
    if (await _local.coachSeen(CoachKeys.bucketsRevision)) return;
    if (isClosed) return;
    showRevisionCoachTip.value = true;
  }

  Future<void> dismissRevisionCoachTip() async {
    if (!showRevisionCoachTip.value) return;
    showRevisionCoachTip.value = false;
    await _local.markCoachSeen(CoachKeys.bucketsRevision);
  }

  Future<void> _loadNextDropTimes(List<Bucket> list) async {
    try {
      final ids = list.map((b) => b.id).toList();
      final drops = await _bucketRepo.fetchNextDropTimes(ids);
      nextDropMap.assignAll(drops);
    } on RepoException catch (_) {
      // non-critical; cards render without next-drop when unavailable
    }
  }

  void _runStagger() {
    if (isClosed) return;
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return;
    staggerController.forward(from: 0);
  }

  Future<void> reload({bool forceRemote = false}) async {
    if (isClosed) return;
    staggerController.reset();
    final userId = _auth.currentUserId;
    if (userId == null) return;

    if (forceRemote) {
      try {
        final fresh = await _bucketRepo.fetchAll(userId, forceRemote: true);
        final active = await _bucketRepo.fetchActiveBuckets(userId);
        buckets.assignAll(fresh);
        activeBucketIds
          ..clear()
          ..addAll(active.map((b) => b.id));
        bucketCount.value = fresh.length;

        final stats = await _bucketRepo.fetchAllHeatStats(userId);
        heatStats.assignAll(stats);

        final mastery = await _bucketRepo.fetchAllMastery(userId);
        masteryMap.assignAll(mastery);

        nodeCount.value = await _bucketRepo.fetchTotalNodeCount(userId);
        _syncStatus.clearUpdates();

        _loadNextDropTimes(fresh);
        _runStagger();
      } on RepoException catch (_) {
        // keep showing cached data
      }
    } else {
      await _loadData();
    }
  }

  void onFilterChanged(BucketFilter filter) {
    RecallHaptics.selection();
    activeFilter.value = filter;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void toggleSearch() {
    isSearchVisible.toggle();
    if (!isSearchVisible.value) searchQuery.value = '';
  }

  /// Free-tier bucket cap hit: send the user to the paywall.
  void onBucketLimitTap() {
    RecallHaptics.light();
    _metrics.downgradedGateHit('buckets_fab');
    _tierService.openPaywall();
  }

  void onCreateNoteTap() {
    RecallHaptics.light();
    Get.toNamed(Routes.nodeAdd);
  }

  Future<void> createBucket(
    String name,
    String? description, {
    bool srEnabled = true,
  }) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      await _bucketRepo.create(Bucket(
        id: '',
        userId: userId,
        name: trimmed,
        description: description,
        srEnabled: srEnabled,
      ));
      RecallHaptics.medium();
      await reload(forceRemote: true);
    } on RepoException catch (e) {
      setError(e.isOffline
          ? 'You\'re offline. Check your connection and try again.'
          : e.message);
    }
  }

  void onBucketTap(Bucket bucket) {
    RecallHaptics.selection();
    Get.toNamed(Routes.bucket, arguments: {
      'bucket_id': bucket.id,
      'read_only': isReadOnly(bucket),
    });
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    staggerController.dispose();
    super.onClose();
  }
}
