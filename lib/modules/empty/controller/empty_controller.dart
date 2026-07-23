import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/drop_readiness.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/insights_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../shell/controller/shell_controller.dart';
import '../empty_variant.dart';

class EmptyController extends BaseController {
  final _auth = Get.find<AuthService>();
  final _profileRepo = Get.find<ProfileRepository>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _insightsRepo = Get.find<InsightsRepository>();
  final _metrics = Get.find<MetricsService>();
  final _syncStatus = Get.find<SyncStatusService>();

  late final EmptyVariant variant;

  final RxInt streak = 0.obs;
  final RxString formattedDate = ''.obs;
  final Rxn<DateTime> nextDropAt = Rxn<DateTime>();
  final RxBool hasNotes = true.obs;
  final RxBool pushEnabled = false.obs;
  final RxString dropFrequency = kDefaultDropFrequency.obs;
  final RxInt daysWithReviews = 0.obs;
  final Rxn<DoneFastBanner> doneFastBanner = Rxn<DoneFastBanner>();

  RecallTab get activeTab {
    switch (variant) {
      case EmptyVariant.buckets:
        return RecallTab.buckets;
      case EmptyVariant.today:
        return RecallTab.today;
      case EmptyVariant.insights:
        return RecallTab.insights;
    }
  }

  @override
  void onInit() {
    super.onInit();
    variant = _resolveVariant();
    _formattedDateNow();
    _load();
  }

  EmptyVariant _resolveVariant() {
    final args = Get.arguments;
    if (args is Map && args['variant'] is EmptyVariant) {
      return args['variant'] as EmptyVariant;
    }
    if (args is Map && args['variant'] is String) {
      switch (args['variant'] as String) {
        case 'buckets':
          return EmptyVariant.buckets;
        case 'today':
          return EmptyVariant.today;
        case 'insights':
          return EmptyVariant.insights;
      }
    }
    if (args is Map && args['days'] is int) {
      return EmptyVariant.insights;
    }
    return EmptyVariantRoute.fromRoute(Get.currentRoute) ??
        EmptyVariant.today;
  }

  void _formattedDateNow() {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    formattedDate.value = '${days[now.weekday - 1]} ${now.day}';
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    try {
      final profile = await _profileRepo.fetchProfile(userId);
      streak.value = profile?.currentStreak ?? 0;
      pushEnabled.value = profile?.pushOptIn ?? false;
      dropFrequency.value =
          profile?.dropFrequency ?? kDefaultDropFrequency;

      switch (variant) {
        case EmptyVariant.buckets:
          _track('empty_buckets_viewed', {});
        case EmptyVariant.today:
          await _loadTodayExtras(userId);
          _track('all_caught_up_viewed', {});
        case EmptyVariant.insights:
          if (argsDaysFromRoute != null) {
            daysWithReviews.value = argsDaysFromRoute!;
          } else {
            await _loadInsightsDays(userId);
          }
          _track('insights_empty_viewed', {'days': daysWithReviews.value});
      }

      _syncStatus.setOffline(false);
      setSuccess();
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError("You're offline. Check your connection and try again.");
      } else {
        setError(e.message);
      }
    }
  }

  int? get argsDaysFromRoute {
    final args = Get.arguments;
    if (args is Map && args['days'] is int) return args['days'] as int;
    return null;
  }

  Future<void> _loadTodayExtras(String userId) async {
    final nodeCount = await _bucketRepo.fetchTotalNodeCount(userId);
    hasNotes.value = nodeCount > 0;

    final results = await Future.wait([
      _bucketRepo.fetchGlobalNextDrop(),
      _metrics.consumeDoneFastBanner(),
    ]);

    nextDropAt.value = results[0] as DateTime?;
    doneFastBanner.value = results[1] as DoneFastBanner?;
  }

  Future<void> _loadInsightsDays(String userId) async {
    if (argsDaysFromRoute != null) return;
    final summary = await _insightsRepo.fetchSummary(userId);
    daysWithReviews.value = summary?.daysWithReviews ?? 0;
  }

  void onMakeBucket() {
    RecallHaptics.light();
    Get.toNamed(Routes.nodeAdd);
  }

  void openQuiz() {
    final shell = Get.find<ShellController>();
    shell.onTabSelected(RecallTab.quiz);
    if (Get.currentRoute.startsWith('/empty')) {
      Get.offAllNamed(Routes.quiz);
    }
  }

  /// Updates Cards-before-a-Drop from the Today caught-up explainer CTA.
  Future<void> setDropFrequency(String value) async {
    if (value == dropFrequency.value) return;
    final userId = _auth.currentUserId;
    if (userId == null) return;
    final prev = dropFrequency.value;
    RecallHaptics.selection();
    dropFrequency.value = value;
    try {
      await _profileRepo.updatePreferences(userId, {'drop_frequency': value});
    } on RepoException {
      dropFrequency.value = prev;
    }
  }

  void onAddNote() {
    RecallHaptics.selection();
    Get.toNamed(Routes.nodeAdd);
  }

  void onStartReview() {
    RecallHaptics.light();
    final shell = Get.find<ShellController>();
    shell.onTabSelected(RecallTab.today);
    if (Get.currentRoute.startsWith('/empty')) {
      Get.offAllNamed(Routes.today);
    }
  }

  Future<void> reload() => _load();

  void _track(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'analytics',
      message: name,
      data: params,
    ));
  }
}
