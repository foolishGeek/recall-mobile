// Recall · InsightsController. Loads the proof-of-value ledger for the active
// tier via one `insights_dashboard_rpc` round-trip (+ RAM TTL cache).
//
// Free / downgraded → stat grid + heatmap + locked premium teasers.
// Premium / relaxed → retention hero + curve, mastery rings, weak topics,
//                     velocity + Drop-open.
// `< 7` days of reviews → the InsightsEmpty portrait gate (rendered in-tab).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/gates/feature.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/insights_heatmap.dart';
import '../../../core/utils/load_cache_ttl.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/insights/insights_repository.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/services/billing/tier_service.dart';
import '../../../data/services/metrics/metrics_service.dart';
import '../../../data/services/shared/repo_exception.dart';
import '../../../data/services/sync/sync_status_service.dart';
import '../../shell/controller/shell_controller.dart';

/// One bucket's mastery ring (premium mastery card).
typedef MasteryRing = ({String label, double progress, double heat});

class InsightsController extends BaseController
    with GetTickerProviderStateMixin {
  final InsightsRepository _insights = Get.find();
  final AuthService _auth = Get.find();
  final TierService _tier = Get.find();
  final SyncStatusService _syncStatus = Get.find();
  final _metrics = Get.find<MetricsService>();

  late final AnimationController staggerController;
  Worker? _tabWorker;

  DateTime? _paintedAt;
  bool _loadInFlight = false;

  // ── Tier ──────────────────────────────────────────────────────────────
  TierGate get gate => _tier.gate;
  bool get isPremium => gate.isPremium;

  /// Full Insights ledger (incl. retention simulation) while
  /// `limits_profile=relaxed` or when truly premium.
  bool get showSimulation => gate.access(Feature.insightsFull).allowed;

  // ── Gate ──────────────────────────────────────────────────────────────
  /// `< 7` distinct review days → render the InsightsEmpty portrait instead.
  final RxBool isGated = false.obs;
  final RxInt daysWithReviews = 0.obs;

  // ── Free + shared stats ───────────────────────────────────────────────
  final Rxn<InsightsSummary> summary = Rxn<InsightsSummary>();
  final Rx<List<List<int>>> heatmap = Rx<List<List<int>>>(const []);

  // Free-tier loss-aversion teaser ("protecting N notes") + locked-curve preview.
  final RxInt totalNodes = 0.obs;
  final Rxn<double> cachedWithRecall = Rxn<double>();
  final Rxn<double> cachedBaseline = Rxn<double>();

  // ── Premium cards ─────────────────────────────────────────────────────
  final Rxn<RetentionSimulation> retention = Rxn<RetentionSimulation>();
  final RxList<MasteryRing> masteryRings = <MasteryRing>[].obs;
  final RxInt bucketCount = 0.obs;
  final RxList<WeakTopic> weakTopics = <WeakTopic>[].obs;
  final RxList<DailyActivity> velocity = <DailyActivity>[].obs;
  final Rxn<NotificationStats> notifStats = Rxn<NotificationStats>();
  final RxList<NotificationDaily> notifDaily = <NotificationDaily>[].obs;

  /// Per-card soft-failure flags (a failed card stays quiet; never breaks the
  /// screen). Keys: retention, mastery, weak, velocity, drops, heatmap.
  final RxMap<String, bool> cardError = <String, bool>{}.obs;

  /// First-reveal flag for the dramatized retention curve (presentation only).
  bool _retentionRevealed = false;
  bool get firstRetentionReveal {
    if (_retentionRevealed) return false;
    _retentionRevealed = true;
    return true;
  }

  // ── Derived (presentation) ────────────────────────────────────────────
  int get streak => summary.value?.currentStreak ?? 0;
  int get dueToday => summary.value?.dueToday ?? 0;
  int get overdue => summary.value?.overdue ?? 0;

  /// Adherence as a 0..100 percent, or null when there were no due reviews to
  /// adhere to (rendered as "—", never a shaming red). [D-VIEW-2].
  double? get adherencePct {
    final a = summary.value?.adherence7d;
    return a == null ? null : (a * 100);
  }

  double get avgVelocity {
    if (velocity.isEmpty) return 0;
    final total = velocity.fold<int>(0, (sum, d) => sum + d.reviewCount);
    return total / velocity.length;
  }

  bool get _hasPaintedData => summary.value != null || isGated.value;

  bool get _memoryFresh {
    final at = _paintedAt;
    if (at == null || !_hasPaintedData) return false;
    return DateTime.now().difference(at) <= kInsightsMemoryTtl;
  }

  @override
  void onInit() {
    super.onInit();
    staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _load();

    final shell = Get.find<ShellController>();
    _tabWorker = ever(shell.currentTab, (RecallTab tab) {
      if (isClosed) return;
      if (tab == RecallTab.insights) onTabVisible();
    });
  }

  /// Tab revisit: paint from Cache 2 when fresh; never blank a good screen.
  void onTabVisible() {
    if (_memoryFresh) {
      unawaited(_quietRefresh());
      return;
    }
    unawaited(_load(forceNetwork: true));
  }

  Future<void> _load({bool forceNetwork = false}) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      setError('Sign in to see Insights.');
      return;
    }
    if (_loadInFlight) return;
    _loadInFlight = true;

    final sw = kDebugMode ? (Stopwatch()..start()) : null;

    try {
      final mem = _insights.memoryDashboard;
      if (!forceNetwork && mem != null) {
        _applyDashboard(mem);
        setSuccess();
        _runStagger();
        _trackViewed();
        unawaited(_quietRefresh());
        return;
      }

      if (!_hasPaintedData) setLoading();
      cardError.clear();

      final dashboard = await _insights.fetchDashboard(
        bypassMemory: forceNetwork,
      );
      if (isClosed) return;
      _syncStatus.setOffline(false);
      _applyDashboard(dashboard);
      setSuccess();
      _runStagger();
      _trackViewed();
    } on RepoException catch (e) {
      if (_hasPaintedData) {
        if (e.isOffline) _syncStatus.setOffline(true);
        return;
      }
      handleLoadError(e, _syncStatus);
    } finally {
      _loadInFlight = false;
      if (sw != null) {
        debugPrint('[perf] insights_load ${sw.elapsedMilliseconds}ms');
      }
    }
  }

  /// Background refresh without skeleton / stagger reset.
  Future<void> _quietRefresh() async {
    if (_loadInFlight || isClosed) return;
    _loadInFlight = true;
    try {
      final dashboard = await _insights.fetchDashboard(bypassMemory: true);
      if (isClosed) return;
      _syncStatus.setOffline(false);
      _applyDashboard(dashboard, quiet: true);
    } on RepoException catch (e) {
      if (e.isOffline) _syncStatus.setOffline(true);
    } finally {
      _loadInFlight = false;
    }
  }

  void _applyDashboard(InsightsDashboard d, {bool quiet = false}) {
    final s = d.summary;
    if (s != null) {
      summary.value = (
        currentStreak: s.currentStreak,
        adherence7d: s.adherence7d,
        daysWithReviews: s.daysWithReviews,
        dueToday: s.dueToday,
        overdue: s.overdue,
      );
      daysWithReviews.value = s.daysWithReviews;
      isGated.value = s.daysWithReviews < 7;
    }

    cardError
      ..clear()
      ..addEntries(d.sectionErrors.map((k) => MapEntry(k, true)));

    if (isGated.value) {
      _paintedAt = DateTime.now();
      return;
    }

    if (!d.sectionErrors.contains('heatmap')) {
      heatmap.value = InsightsHeatmap.build(d.dailyActivity);
    }

    if (d.simulationAllowed && showSimulation) {
      if (d.retention != null && !d.sectionErrors.contains('retention')) {
        retention.value = d.retention;
      }
      if (!d.sectionErrors.contains('mastery')) {
        bucketCount.value = d.bucketCount;
        masteryRings.assignAll(
          d.masteryRings
              .map((r) => (label: r.label, progress: r.progress, heat: r.heat)),
        );
      }
      if (!d.sectionErrors.contains('weak')) {
        weakTopics.assignAll(
          d.weakTopics
              .map(
                (w) => (
                  nodeId: w.nodeId,
                  title: w.title,
                  bucketId: w.bucketId,
                  bucketName: w.bucketName,
                  comfort: w.comfort,
                  priority: w.priority,
                  difficulty: w.difficulty,
                ),
              )
              .toList(),
        );
      }
      if (!d.sectionErrors.contains('velocity')) {
        velocity.assignAll(d.velocity);
      }
      if (!d.sectionErrors.contains('drops')) {
        notifStats.value = d.notificationStats;
        notifDaily.assignAll(d.notificationDaily);
      }
      if (!quiet &&
          (d.retentionPending || d.retentionStale || d.retention == null)) {
        unawaited(_refreshRetentionInBackground());
      }
    } else {
      if (d.lifetime != null && !d.sectionErrors.contains('teaser')) {
        totalNodes.value = d.lifetime!.totalNodes;
      }
      if (!d.sectionErrors.contains('preview')) {
        cachedWithRecall.value = d.teaserWithRecall;
        cachedBaseline.value = d.teaserBaseline;
      }
    }

    _paintedAt = DateTime.now();
  }

  /// Heavy simulate via Edge Function — never blocks first paint.
  Future<void> _refreshRetentionInBackground() async {
    if (!showSimulation || isClosed) return;
    try {
      final r = await _insights.resolveRetention(force: true);
      if (isClosed || r == null) return;
      retention.value = r;
      cardError['retention'] = false;
      _insights.clearMemoryCache();
    } on RepoException {
      if (retention.value == null) cardError['retention'] = true;
    } catch (_) {
      if (retention.value == null) cardError['retention'] = true;
    }
  }

  void _trackViewed() {
    _track('insights_viewed', {
      'tier': gate.tier.name,
      'gated': isGated.value,
      'premium': isPremium,
      'simulation': showSimulation,
    });
  }

  void _runStagger() {
    if (isClosed) return;
    final reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      staggerController.value = 1.0;
      return;
    }
    staggerController.forward(from: 0);
  }

  Future<void> reload() async {
    if (isClosed) return;
    staggerController.reset();
    _retentionRevealed = false;
    _paintedAt = null;
    _insights.clearMemoryCache();
    await _load(forceNetwork: true);
  }

  // ── Intents ─────────────────────────────────────────────────────────────
  void onLockedBlockTap(String block) {
    RecallHaptics.selection();
    _metrics.downgradedGateHit('insights', params: {'block': block});
    _track('insights_locked_block_tapped', {'block': block});
    _tier.openPaywall();
  }

  void onUnlockTap() {
    RecallHaptics.light();
    _metrics.downgradedGateHit('insights', params: {'block': 'cta'});
    _tier.openPaywall();
  }

  void onStartReview() {
    RecallHaptics.light();
    final shell = Get.find<ShellController>();
    shell.onTabSelected(RecallTab.today);
  }

  void _track(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    staggerController.dispose();
    super.onClose();
  }
}
