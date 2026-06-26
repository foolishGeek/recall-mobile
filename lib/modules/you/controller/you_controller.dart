// Recall · YouController. The profile ledger for the active tier. Read-only:
// every number is server-authoritative (profiles, v_profile_lifetime,
// achievements/user_achievements, the `retention-simulate` EF). The controller
// only orchestrates loads, tier branching, offline fallback, the reveal
// choreography, and the row intents.
//
// Free / downgraded → upgrade-CTA hero, 3-up stats, level card, Settings.
// Premium          → memory-simulation hero + curve, level ring, achievements
//                     (12), lifetime stats, Settings + Manage subscription.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/level_titles.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/insights_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';
import '../../shell/controller/shell_controller.dart';

/// Native OS subscription-management deep links. RevenueCat Customer Center can
/// replace these in S23; today this is the calm, forward-compatible target.
const _kIosManageSubscriptions =
    'https://apps.apple.com/account/subscriptions';
const _kAndroidManageSubscriptions =
    'https://play.google.com/store/account/subscriptions';

const _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The total achievement set is the 12-row canonical seed [D-SCHEMA-1].
const int kAchievementTotal = 12;

class YouController extends BaseController with GetTickerProviderStateMixin {
  final ProfileRepository _profiles = Get.find();
  final InsightsRepository _insights = Get.find();
  final AuthService _auth = Get.find();
  final TierService _tier = Get.find();
  final SyncStatusService _syncStatus = Get.find();

  late final AnimationController staggerController;
  Worker? _tabWorker;

  // ── Tier ──────────────────────────────────────────────────────────────
  TierGate get gate => _tier.gate;
  bool get isPremium => gate.isPremium;

  // ── State (all server-authoritative) ────────────────────────────────────
  final Rxn<Profile> profile = Rxn<Profile>();
  final Rxn<ProfileLifetime> lifetime = Rxn<ProfileLifetime>();
  final RxList<Achievement> achievements = <Achievement>[].obs;
  final RxList<UserAchievement> userAchievements = <UserAchievement>[].obs;
  final Rxn<RetentionSimulation> retention = Rxn<RetentionSimulation>();

  /// Per-card soft-failure flags — a failed card stays quiet, never breaks the
  /// screen. Keys: lifetime, achievements, retention.
  final RxMap<String, bool> cardError = <String, bool>{}.obs;

  /// Achievement ids unlocked since the user last saw this tab — those tiles
  /// spring in (`RecallMotion.bubbly`). Empty on the first load of a session.
  final RxSet<String> newlyUnlocked = <String>{}.obs;
  final Set<String> _seenUnlockedIds = <String>{};
  bool _seenInitialized = false;

  // First-reveal flags (presentation only): the hero fade + curve draw and the
  // XP ring draw should only play on first appearance, not on every rebuild.
  bool _heroRevealed = false;
  bool get firstHeroReveal {
    if (_heroRevealed) return false;
    _heroRevealed = true;
    return true;
  }

  bool _ringRevealed = false;
  bool get firstRingReveal {
    if (_ringRevealed) return false;
    _ringRevealed = true;
    return true;
  }

  // ── Derived (presentation) ───────────────────────────────────────────────
  String get displayName => profile.value?.displayName?.trim().isNotEmpty == true
      ? profile.value!.displayName!.trim()
      : 'Your profile';

  String? get email => _auth.currentEmail;

  /// Uppercase initial for the avatar; falls back to '?' when blank.
  String get avatarInitial {
    final name = profile.value?.displayName?.trim();
    if (name == null || name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

  LevelBand get levelBand => LevelBand.fromProfile(
        xp: profile.value?.xp ?? 0,
        level: profile.value?.level ?? 1,
      );

  String get levelTitle => LevelTitles.forLevel(profile.value?.level ?? 1);

  int get xp => profile.value?.xp ?? 0;
  int get currentStreak => profile.value?.currentStreak ?? 0;
  int get memoriesSaved => profile.value?.memoriesSaved ?? 0;
  int get totalReviews => lifetime.value?.totalReviews ?? 0;

  int get unlockedCount =>
      userAchievements.where((u) => _isInCatalog(u.achievementId)).length;

  /// Earned achievements, most-recently unlocked first (for the badge tiles).
  List<Achievement> get earnedAchievements {
    final byId = {for (final a in achievements) a.id: a};
    final out = <Achievement>[];
    for (final u in userAchievements) {
      final a = byId[u.achievementId];
      if (a != null) out.add(a);
    }
    return out;
  }

  /// "since Mar '25" — null when the join date is unknown.
  String? get memberSinceLabel {
    final d = lifetime.value?.memberSince;
    if (d == null) return null;
    final mon = _kMonthAbbr[(d.month - 1).clamp(0, 11)];
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return "since $mon '$yy";
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
      if (tab == RecallTab.you) reload();
    });
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    cardError.clear();

    // Spine: the profile drives name / level / XP / streak / memories. If it
    // fails we fall to the offline/error state; everything else is best-effort.
    final Profile? p;
    try {
      p = await _profiles.fetchProfile(userId);
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
    profile.value = p;

    await _loadVariant(userId);
    if (isClosed) return;

    setSuccess();
    _runStagger();
    _track('profile_viewed', {'tier': gate.tier.name, 'premium': isPremium});
  }

  /// Loads the tier-specific cards in parallel; each is isolated via [_safe] so
  /// one failure only mutes its own card.
  Future<void> _loadVariant(String userId) async {
    final tasks = <Future<void>>[
      // Lifetime feeds the premium lifetime grid AND the free 3-up reviews stat.
      _safe('lifetime', () async {
        lifetime.value = await _insights.fetchLifetime(userId);
      }),
    ];

    if (isPremium) {
      tasks.addAll([
        _safe('achievements', () => _loadAchievements(userId)),
        _safe('retention', () => _loadRetention(userId)),
      ]);
    }

    await Future.wait(tasks);
  }

  Future<void> _loadAchievements(String userId) async {
    final results = await Future.wait([
      _insights.fetchAchievements(),
      _insights.fetchUserAchievements(userId),
    ]);
    final catalog = results[0] as List<Achievement>;
    final unlocked = results[1] as List<UserAchievement>;
    achievements.assignAll(catalog);
    userAchievements.assignAll(unlocked);
    _diffNewlyUnlocked(unlocked);
  }

  /// Premium retention curve. On EF failure (gate race, maintenance, offline)
  /// fall back to the cached `profiles.retention_*` numbers with a preview curve
  /// so the hero still reads (mirrors InsightsController).
  Future<void> _loadRetention(String userId) async {
    try {
      retention.value = await _insights.simulateRetention();
    } on RepoException {
      final p = profile.value;
      if (p?.retentionWithRecall != null) {
        retention.value = RetentionSimulation(
          withRecallPct: p!.retentionWithRecall!,
          baselinePct: p.retentionBaseline ?? 0,
          curvePoints: const [],
          isProjected: true,
          reviewDaysCount: 0,
          memoriesSaved: p.memoriesSaved,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Marks ids unlocked since the last view as "new" (spring on the tile). The
  /// first load of a session seeds the baseline and springs nothing.
  void _diffNewlyUnlocked(List<UserAchievement> unlocked) {
    final current =
        unlocked.map((u) => u.achievementId).where(_isInCatalog).toSet();
    if (_seenInitialized) {
      newlyUnlocked.assignAll(current.difference(_seenUnlockedIds));
    } else {
      newlyUnlocked.clear();
      _seenInitialized = true;
    }
    _seenUnlockedIds
      ..clear()
      ..addAll(current);
  }

  bool _isInCatalog(String achievementId) =>
      achievements.any((a) => a.id == achievementId);

  /// Runs [body], swallowing RepoExceptions into a per-card flag so a single
  /// failing card never takes down the whole screen (capture scope=you).
  Future<void> _safe(String card, Future<void> Function() body) async {
    try {
      await body();
      cardError[card] = false;
    } on RepoException catch (e) {
      cardError[card] = true;
      Sentry.addBreadcrumb(Breadcrumb(
        category: 'you',
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
    _heroRevealed = false;
    _ringRevealed = false;
    await _load();
  }

  // ── Intents ──────────────────────────────────────────────────────────────
  /// Settings row → push the Settings screen (ListRow emits the selection tick).
  void onSettings() => Get.toNamed(Routes.settings);

  /// Manage subscription → native OS subscription management (ListRow emits the
  /// selection tick). Best-effort: a launch failure is captured, never crashes.
  Future<void> onManageSubscription() async {
    _track('manage_subscription_tapped', {'tier': gate.tier.name});
    final url = Platform.isIOS || Platform.isMacOS
        ? _kIosManageSubscriptions
        : _kAndroidManageSubscriptions;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      await Sentry.captureException(e,
          stackTrace: st,
          withScope: (s) => s.setTag('feature', 'you'));
    }
  }

  /// Free upgrade CTA → light haptic + paywall.
  void onUpgrade() {
    RecallHaptics.light();
    _track('upgrade_cta_tapped', {'tier': gate.tier.name});
    Get.toNamed(Routes.paywall);
  }

  /// Analytics stub — opt-in gated, breadcrumb-only until a provider is wired
  /// (mirrors insights_controller). Safe to call unconditionally.
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
