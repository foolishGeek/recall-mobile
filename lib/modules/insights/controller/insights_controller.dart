// Recall · InsightsController. Loads the proof-of-value ledger for the active
// tier. The screen is read-only: every metric is server-authoritative (views +
// the `retention-simulate` EF). The controller only orchestrates loads, gating,
// tier branching, offline fallback, and the reveal animation.
//
// Free / downgraded → stat grid + heatmap + locked premium teasers.
// Premium          → retention hero + curve, mastery rings, weak topics,
//                     velocity + Drop-open.
// `< 7` days of reviews → the InsightsEmpty portrait gate (rendered in-tab so
// the Insights tab stays active, per docs/13_empty.md).

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/config/limits_config.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/insights_heatmap.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/insights_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';

/// One bucket's mastery ring (premium mastery card).
typedef MasteryRing = ({String label, double progress, double heat});

class InsightsController extends BaseController with GetTickerProviderStateMixin {
  final InsightsRepository _insights = Get.find();
  final BucketRepository _buckets = Get.find();
  final ProfileRepository _profiles = Get.find();
  final AuthService _auth = Get.find();
  final TierService _tier = Get.find();
  final SyncStatusService _syncStatus = Get.find();
  final _metrics = Get.find<MetricsService>();

  late final AnimationController staggerController;
  Worker? _tabWorker;

  // ── Tier ──────────────────────────────────────────────────────────────
  TierGate get gate => _tier.gate;
  bool get isPremium => gate.isPremium;

  /// Full Insights ledger (incl. retention simulation) while
  /// `limits_profile=relaxed` or when truly premium.
  bool get showSimulation {
    if (isPremium) return true;
    if (!Get.isRegistered<LimitsConfig>()) return false;
    // Touch Rx so Obx rebuilds after resume refresh.
    return Get.find<LimitsConfig>().profileRx.value ==
        LimitsConfig.profileRelaxed;
  }

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
      if (tab == RecallTab.insights) reload();
    });
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    cardError.clear();

    // Spine: the summary decides the gate, so it must succeed (or fall to the
    // offline/error state). Everything else is best-effort per card.
    final InsightsSummary? s;
    try {
      s = await _insights.fetchSummary(userId);
      if (isClosed) return;
      _syncStatus.setOffline(false);
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError("You're offline. Check your connection and try again.");
      } else {
        setError(e.message);
      }
      return;
    }

    summary.value = s;
    daysWithReviews.value = s?.daysWithReviews ?? 0;
    isGated.value = (s?.daysWithReviews ?? 0) < 7;

    if (isGated.value) {
      // The portrait gate needs no further data; reveal it calmly.
      setSuccess();
      _runStagger();
      _track('insights_viewed', {'tier': gate.tier.name, 'gated': true});
      return;
    }

    await _loadVariant(userId);
    if (isClosed) return;

    setSuccess();
    _runStagger();
    _track('insights_viewed', {
      'tier': gate.tier.name,
      'gated': false,
      'premium': isPremium,
      'simulation': showSimulation,
    });
  }

  /// Loads the tier-specific cards in parallel; each is isolated so one failure
  /// only mutes its own card.
  Future<void> _loadVariant(String userId) async {
    final common = <Future<void>>[
      _safe('heatmap', () async {
        final activity = await _insights.fetchDailyActivity(userId);
        heatmap.value = InsightsHeatmap.build(activity);
      }),
    ];

    if (showSimulation) {
      await Future.wait([
        ...common,
        _safe('retention', () => _loadRetention(userId)),
        _safe('mastery', () => _loadMastery(userId)),
        _safe('weak', () async => weakTopics.assignAll(
              (await _insights.fetchWeakTopics()).take(3).toList(),
            )),
        _safe('velocity', () async =>
            velocity.assignAll(await _insights.fetchReviewVelocity(userId))),
        _safe('drops', () => _loadDrops(userId)),
      ]);
    } else {
      // Free / downgraded: teaser node count + cached retention for the locked
      // preview. Both are quiet enhancements.
      await Future.wait([
        ...common,
        _safe('teaser', () async {
          final lifetime = await _insights.fetchLifetime(userId);
          totalNodes.value = lifetime?.totalNodes ?? 0;
        }),
        _safe('preview', () async {
          final profile = await _profiles.fetchProfile(userId);
          cachedWithRecall.value = profile?.retentionWithRecall;
          cachedBaseline.value = profile?.retentionBaseline;
        }),
      ]);
    }
  }

  /// Premium retention curve. On EF failure (premium gate race, maintenance,
  /// offline) fall back to the cached `profiles.retention_*` numbers with a
  /// preview curve so the hero still reads.
  Future<void> _loadRetention(String userId) async {
    try {
      retention.value = await _insights.simulateRetention();
    } on RepoException {
      final profile = await _profiles.fetchProfile(userId);
      if (profile?.retentionWithRecall != null) {
        retention.value = RetentionSimulation(
          withRecallPct: profile!.retentionWithRecall!,
          baselinePct: profile.retentionBaseline ?? 0,
          curvePoints: const [],
          isProjected: daysWithReviews.value < 7,
          reviewDaysCount: daysWithReviews.value,
          memoriesSaved: profile.memoriesSaved,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadMastery(String userId) async {
    final results = await Future.wait([
      _buckets.fetchAll(userId),
      _buckets.fetchAllMastery(userId),
      _buckets.fetchAllHeatStats(userId),
    ]);
    final list = results[0] as List<Bucket>;
    final mastery = results[1] as Map<String, double>;
    final heat = results[2] as Map<String, BucketHeatStats>;

    bucketCount.value = list.length;

    // Most-populated buckets first; cap at 4 rings (design: 4-up grid).
    final sorted = [...list]..sort((a, b) {
        final na = heat[a.id]?.nodeCount ?? 0;
        final nb = heat[b.id]?.nodeCount ?? 0;
        return nb.compareTo(na);
      });

    masteryRings.assignAll(sorted.take(4).map((b) {
      final stats = heat[b.id];
      final density = (stats == null || stats.nodeCount == 0)
          ? 0.3
          : (stats.dueCount / stats.nodeCount).clamp(0.0, 1.0);
      return (
        label: b.name,
        progress: (mastery[b.id] ?? 0).clamp(0.0, 1.0),
        heat: density,
      );
    }).toList());
  }

  Future<void> _loadDrops(String userId) async {
    final results = await Future.wait([
      _insights.fetchNotificationStats(userId),
      _insights.fetchNotificationDaily(userId, limit: 7),
    ]);
    notifStats.value = results[0] as NotificationStats?;
    notifDaily.assignAll(results[1] as List<NotificationDaily>);
  }

  /// Runs [body], swallowing RepoExceptions into a per-card error flag so a
  /// single failing card never takes down the whole Insights screen.
  Future<void> _safe(String card, Future<void> Function() body) async {
    try {
      await body();
      cardError[card] = false;
    } on RepoException catch (e) {
      cardError[card] = true;
      Sentry.addBreadcrumb(Breadcrumb(
        category: 'insights',
        message: 'card "$card" load failed (non-fatal)',
        data: {'code': e.code.wire},
        level: SentryLevel.warning,
      ));
    }
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
    await _load();
  }

  // ── Intents ─────────────────────────────────────────────────────────────
  /// Locked premium teaser tapped → quiet selection haptic + paywall.
  void onLockedBlockTap(String block) {
    RecallHaptics.selection();
    _metrics.downgradedGateHit('insights', params: {'block': block});
    _track('insights_locked_block_tapped', {'block': block});
    _tier.openPaywall();
  }

  /// "Unlock the full picture" CTA → light haptic + paywall.
  void onUnlockTap() {
    RecallHaptics.light();
    _metrics.downgradedGateHit('insights', params: {'block': 'cta'});
    _tier.openPaywall();
  }

  /// Empty-state CTA → jump to the Today tab to start a review.
  void onStartReview() {
    RecallHaptics.light();
    final shell = Get.find<ShellController>();
    shell.onTabSelected(RecallTab.today);
  }

  /// Analytics stub — opt-in gated, breadcrumb-only until a full analytics
  /// service is wired (mirrors node_controller). Safe to call unconditionally.
  void _track(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'analytics',
      message: name,
      data: params,
    ));
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    staggerController.dispose();
    super.onClose();
  }
}
