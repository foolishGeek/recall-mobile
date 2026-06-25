import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';

enum BucketFilter { all, active, cooling, aToZ }

class BucketsController extends BaseController
    with GetTickerProviderStateMixin {
  final _auth = Get.find<AuthService>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _tierService = Get.find<TierService>();
  final _syncStatus = Get.find<SyncStatusService>();

  final RxList<Bucket> buckets = <Bucket>[].obs;
  final RxInt bucketCount = 0.obs;
  final RxInt nodeCount = 0.obs;
  final RxMap<String, BucketHeatStats> heatStats =
      <String, BucketHeatStats>{}.obs;
  final RxMap<String, double> masteryMap = <String, double>{}.obs;
  final RxMap<String, DateTime> nextDropMap = <String, DateTime>{}.obs;
  final RxString searchQuery = ''.obs;
  final Rx<BucketFilter> activeFilter = BucketFilter.all.obs;
  final RxBool isSearchVisible = false.obs;

  late final AnimationController staggerController;

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

  bool get fabLocked =>
      _tierService.gate.showBucketFabLock(currentBucketCount: buckets.length);

  bool isCooling(Bucket b) =>
      b.cooldownUntil != null && b.cooldownUntil!.isAfter(DateTime.now());

  bool isReadOnly(int index) => _tierService.gate.isBucketReadOnly(index);

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

  String nextDropLabel(Bucket b) {
    if (isCooling(b)) return 'COOLING';
    final dt = nextDropMap[b.id];
    if (dt == null) return 'NEXT DROP';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return 'NEXT DROP \u00B7 $h:$m';
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
    ever(shell.currentTab, (RecallTab tab) {
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
        _bucketRepo.fetchAllHeatStats(userId),
        _bucketRepo.fetchAllMastery(userId),
        _bucketRepo.fetchTotalNodeCount(userId),
      ]);

      final loadedBuckets = results[0] as List<Bucket>;

      if (loadedBuckets.isEmpty) {
        setSuccess();
        Get.offAllNamed(Routes.emptyBuckets);
        return;
      }

      buckets.assignAll(loadedBuckets);
      bucketCount.value = loadedBuckets.length;
      heatStats.assignAll(results[1] as Map<String, BucketHeatStats>);
      masteryMap.assignAll(results[2] as Map<String, double>);
      nodeCount.value = results[3] as int;

      _syncStatus.setOffline(false);
      setSuccess();
      _runStagger();

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
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return;
    staggerController.forward(from: 0);
  }

  Future<void> reload({bool forceRemote = false}) async {
    staggerController.reset();
    final userId = _auth.currentUserId;
    if (userId == null) return;

    if (forceRemote) {
      try {
        final fresh = await _bucketRepo.fetchAll(userId, forceRemote: true);
        buckets.assignAll(fresh);
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

  void onFabTap() {
    RecallHaptics.light();
    if (fabLocked) {
      Get.toNamed(Routes.paywall);
    } else {
      Get.toNamed(Routes.nodeAdd);
    }
  }

  void onBucketTap(Bucket bucket, int index) {
    RecallHaptics.selection();
    Get.toNamed(Routes.bucket, arguments: {
      'bucket_id': bucket.id,
      'read_only': isReadOnly(index),
    });
  }

  @override
  void onClose() {
    staggerController.dispose();
    super.onClose();
  }
}
