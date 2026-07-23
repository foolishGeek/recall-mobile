import 'dart:async';

import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/memory_strength.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/cooling_period_selector.dart';
import '../../../core/widgets/reminder_style_selector.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';
import '../../buckets/controller/buckets_controller.dart';

class BucketController extends BaseController {
  BucketController(
    this._auth,
    this._bucketRepo,
    this._nodeRepo,
    this._aiRepo,
    this._tierService,
    this._local,
    this._profiles,
  );

  final AuthService _auth;
  final BucketRepository _bucketRepo;
  final NodeRepository _nodeRepo;
  final AiRepository _aiRepo;
  final TierService _tierService;
  final LocalStore _local;
  final ProfileRepository _profiles;

  late final String bucketId;
  final Rxn<Bucket> bucket = Rxn<Bucket>();
  final RxDouble mastery = 0.0.obs;
  final RxList<Node> nodes = <Node>[].obs;
  final RxBool readOnly = false.obs;
  final RxBool isSummarizing = false.obs;
  final Rxn<SummarizeResult> summaryResult = Rxn<SummarizeResult>();
  final RxnString summaryError = RxnString();

  /// Account-wide Reminder style (profiles.drop_frequency). Reminder is one
  /// setting for the whole app, so bucket config shows it as read-only + a
  /// deep-link to Settings rather than a per-bucket lever.
  final RxString accountDropFrequency = 'daily'.obs;

  // Sorting
  final RxInt sortModeIndex = 0.obs;
  static const _sortModes = ['due ↓', 'due ↑', 'A → Z', 'newest'];

  String get sortLabel => 'Sorted · ${_sortModes[sortModeIndex.value]}';

  void cycleSortMode() {
    RecallHaptics.selection();
    sortModeIndex.value = (sortModeIndex.value + 1) % _sortModes.length;
    _applySorting();
  }

  void _applySorting() {
    switch (sortModeIndex.value) {
      case 0: // due ↓ (earliest due first; nulls last)
        nodes.sort((a, b) {
          final ad = a.dueAt;
          final bd = b.dueAt;
          if (ad == null && bd == null) return b.priority.compareTo(a.priority);
          if (ad == null) return 1;
          if (bd == null) return -1;
          final c = ad.compareTo(bd);
          return c != 0 ? c : b.priority.compareTo(a.priority);
        });
        break;
      case 1: // due ↑ (latest due first)
        nodes.sort((a, b) {
          final ad = a.dueAt;
          final bd = b.dueAt;
          if (ad == null && bd == null) return b.priority.compareTo(a.priority);
          if (ad == null) return 1;
          if (bd == null) return -1;
          final c = bd.compareTo(ad);
          return c != 0 ? c : b.priority.compareTo(a.priority);
        });
        break;
      case 2: // A → Z
        nodes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 3: // newest
        nodes.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
    }
  }

  // ── Draft state for config (deferred save) ──
  // Only Cooling period is a per-bucket deferred lever now. Reminder style is
  // account-wide; Memory strength writes immediately (different RPC).
  final RxInt draftCoolingIndex = 2.obs; // default 14d
  final RxnInt draftCustomDays = RxnInt(); // set when cooling index == Custom
  final RxBool hasPendingChanges = false.obs;
  final RxBool isSavingConfig = false.obs;

  /// Per-bucket memory strength prefs (null until loaded).
  final Rxn<SchedulingPrefs> schedulingPrefs = Rxn<SchedulingPrefs>();

  double get memoryStrength => schedulingPrefs.value?.effective ?? 0.90;
  bool get memoryUsesDefault =>
      !(schedulingPrefs.value?.hasBucketOverride ?? false);

  /// Reminder style as a plain word for the setup recipe.
  String get _reminderWord {
    switch (accountDropFrequency.value) {
      case 'weekly':
        return 'gentle';
      case '3xwk':
        return 'standard';
      case 'asap':
        return 'ASAO';
      default:
        return 'persistent';
    }
  }

  /// A legible, plain-English recipe of the current setup for the entry card,
  /// e.g. "Balanced · standard nudges · rests 14 days".
  String get configRecipe {
    final mem = memoryStrengthLabelFor(memoryStrength);
    final cool = CoolingPeriodSelector.readoutFor(
            draftCoolingIndex.value, draftCustomDays.value)
        .toLowerCase();
    return '$mem · $_reminderWord nudges · $cool';
  }

  int get accountReminderIndex =>
      ReminderStyleSelector.indexForDbValue(accountDropFrequency.value);

  TierGate get gate => _tierService.gate;
  bool get hasNodes => nodes.isNotEmpty;
  int get nodeCount => nodes.length;

  int get dueCount {
    final now = DateTime.now().toUtc();
    return nodes
        .where((n) =>
            n.srEnabled && n.dueAt != null && !n.dueAt!.isAfter(now))
        .length;
  }

  int get overdueCount {
    final now = DateTime.now().toUtc();
    return nodes
        .where((n) =>
            n.srEnabled &&
            n.dueAt != null &&
            n.dueAt!.isBefore(now.subtract(const Duration(days: 1))))
        .length;
  }

  // Config maps — cooling_period is a Postgres interval, so we save "N days".
  static const coolingLabels = ['3d', '7d', '14d', '30d', 'Custom'];
  static const _coolingPresetDays = [3, 7, 14, 30];
  static const _customCoolingIndex = 4;

  int get coolingIndex => draftCoolingIndex.value;
  int? get customCoolingDays => draftCustomDays.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    bucketId = args['bucket_id'] as String? ?? '';
    readOnly.value = args['read_only'] as bool? ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    if (bucketId.isEmpty) {
      setError('No bucket ID provided.');
      return;
    }
    setLoading();
    try {
      final userId = _auth.currentUserId;
      final futures = <Future<Object?>>[
        _bucketRepo.fetchById(bucketId),
        _bucketRepo.fetchMastery(bucketId),
        _nodeRepo.fetchByBucket(bucketId),
      ];
      if (userId != null) {
        futures.add(_bucketRepo.fetchActiveBuckets(userId));
      }
      final results = await Future.wait(futures);
      final loadedBucket = results[0] as Bucket?;
      if (loadedBucket == null) {
        setError('Bucket not found.');
        return;
      }
      bucket.value = loadedBucket;
      mastery.value = (results[1] as double?) ?? 0.0;
      nodes.assignAll(results[2] as List<Node>);

      if (results.length > 3) {
        final active = results[3] as List<Bucket>;
        final activeIds = active.map((b) => b.id).toSet();
        if (_tierService.isDowngraded && !_tierService.gate.isRelaxed) {
          readOnly.value = !activeIds.contains(bucketId);
        }
      }

      _syncDraftFromBucket(loadedBucket);
      hasPendingChanges.value = false;
      setSuccess();
      unawaited(_maybeShowSwipeHint());
      unawaited(_loadSchedulingPrefs());
      if (userId != null) unawaited(_loadAccountReminder(userId));
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  /// Loads the account-wide Reminder style so the setup recipe + config screen
  /// can show it honestly (it is not a per-bucket lever).
  Future<void> _loadAccountReminder(String userId) async {
    try {
      final profile = await _profiles.fetchProfile(userId);
      if (profile != null) accountDropFrequency.value = profile.dropFrequency;
    } on RepoException catch (_) {
      // Non-critical; recipe falls back to the default word.
    }
  }

  Future<void> _loadSchedulingPrefs() async {
    try {
      schedulingPrefs.value =
          await _profiles.getSchedulingPrefs(bucketId: bucketId);
    } on RepoException catch (_) {
      // Non-critical; selector falls back to Balanced 0.90.
    }
  }

  /// Sets a per-bucket memory-strength override (immediate write — not deferred
  /// with cooling/frequency, because it hits a different RPC).
  Future<void> setBucketMemoryStrength(double retention) async {
    if (readOnly.value) return;
    final prev = schedulingPrefs.value;
    try {
      RecallHaptics.selection();
      schedulingPrefs.value = await _profiles.setSchedulingPrefs(
        bucketId: bucketId,
        targetRetention: retention,
      );
    } on RepoException catch (e, st) {
      schedulingPrefs.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  /// Clears the per-bucket override so the bucket inherits the user default.
  Future<void> clearBucketMemoryStrength() async {
    if (readOnly.value) return;
    final prev = schedulingPrefs.value;
    try {
      RecallHaptics.selection();
      schedulingPrefs.value = await _profiles.setSchedulingPrefs(
        bucketId: bucketId,
        targetRetention: null,
      );
    } on RepoException catch (e, st) {
      schedulingPrefs.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  void _syncDraftFromBucket(Bucket b) {
    final days = b.coolingPeriodDuration?.inDays;
    final presetIndex =
        days == null ? -1 : _coolingPresetDays.indexOf(days);
    if (presetIndex >= 0) {
      draftCoolingIndex.value = presetIndex;
      draftCustomDays.value = null;
    } else if (days != null && days > 0) {
      // Non-preset interval → treat as a custom day count so it survives reload.
      draftCoolingIndex.value = _customCoolingIndex;
      draftCustomDays.value = days;
    } else {
      draftCoolingIndex.value = 2; // default 14d
      draftCustomDays.value = null;
    }
  }

  /// Maps the current cooling draft to a Postgres interval string ("N days").
  String _coolingDbValue() {
    if (draftCoolingIndex.value == _customCoolingIndex) {
      final days = (draftCustomDays.value ?? 14).clamp(1, 365);
      return '$days days';
    }
    final idx = draftCoolingIndex.value.clamp(0, _coolingPresetDays.length - 1);
    return '${_coolingPresetDays[idx]} days';
  }

  Future<void> reload() async {
    await _loadData();
  }

  // ── Config draft changes (no immediate API call) ──

  void onCoolingChanged(int index) {
    if (readOnly.value) return;
    RecallHaptics.selection();
    draftCoolingIndex.value = index.clamp(0, coolingLabels.length - 1);
    if (draftCoolingIndex.value != _customCoolingIndex) {
      draftCustomDays.value = null;
    }
    hasPendingChanges.value = true;
  }

  /// Called after the custom-days dialog resolves. Stores the day count and
  /// pins the cooling selection to the Custom slot.
  void onCustomCoolingChanged(int days) {
    if (readOnly.value) return;
    RecallHaptics.selection();
    draftCoolingIndex.value = _customCoolingIndex;
    draftCustomDays.value = days;
    hasPendingChanges.value = true;
  }

  void onDiscardConfig() {
    RecallHaptics.selection();
    if (bucket.value != null) _syncDraftFromBucket(bucket.value!);
    hasPendingChanges.value = false;
  }

  // ── Save config (batch update) ──

  Future<void> onSaveConfig() async {
    if (!hasPendingChanges.value) return;
    RecallHaptics.medium();
    isSavingConfig.value = true;

    final coolingVal = _coolingDbValue();

    try {
      final updated = await _bucketRepo.update(bucketId, {
        'cooling_period': coolingVal,
      });
      bucket.value = updated;
      _syncDraftFromBucket(updated);
      hasPendingChanges.value = false;

      // Notify the buckets list so it reflects the change on back-navigation
      _refreshBucketsList();
    } on RepoException catch (e, st) {
      // Revert draft to server state on failure
      if (bucket.value != null) _syncDraftFromBucket(bucket.value!);
      hasPendingChanges.value = false;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    } finally {
      isSavingConfig.value = false;
    }
  }

  void _refreshBucketsList() {
    try {
      final bucketsCtrl = Get.find<BucketsController>();
      bucketsCtrl.reload();
    } catch (_) {
      // BucketsController might not be registered if deep-linked
    }
  }

  // ── AI ──

  Future<void> onSummarizeTap() async {
    RecallHaptics.light();
    if (isSummarizing.value) return;
    isSummarizing.value = true;
    summaryError.value = null;
    try {
      summaryResult.value = await _aiRepo.summarize(
        scope: 'bucket',
        bucketId: bucketId,
      );
    } on RepoException catch (e, st) {
      summaryError.value = e.message;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    } finally {
      isSummarizing.value = false;
    }
  }

  void onAskAiTap() {
    RecallHaptics.light();
    Get.toNamed(Routes.aiChat, arguments: {
      'bucket_ids': [bucketId],
    });
  }

  // ── Edit (name + description) ──

  Future<void> onEditBucket(String newName, String? newDescription) async {
    if (readOnly.value) return;
    final name = newName.trim();
    if (name.isEmpty) return;
    final prev = bucket.value;
    if (prev == null) return;
    final description = newDescription?.trim() ?? '';

    bucket.value = prev.copyWith(name: name, description: description);
    try {
      final updated = await _bucketRepo.update(bucketId, {
        'name': name,
        'description': description,
      });
      bucket.value = updated;
      _refreshBucketsList();
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  // ── Description ──

  Future<void> onEditDescription(String newDescription) async {
    if (readOnly.value) return;
    final prev = bucket.value;
    if (prev == null) return;
    final trimmed = newDescription.trim();

    bucket.value = prev.copyWith(description: trimmed);
    try {
      final updated =
          await _bucketRepo.update(bucketId, {'description': trimmed});
      bucket.value = updated;
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  // ── Per-bucket spaced-revision toggle (skip whole bucket) ──

  bool get bucketSrEnabled => bucket.value?.srEnabled ?? true;

  /// Turns spaced revision on/off for the whole bucket: flips the bucket default
  /// (applied to future notes) AND bulk-applies to every existing note so the
  /// choice is consistent. Optimistic with revert on failure.
  Future<void> setBucketSrEnabled(bool enabled) async {
    if (readOnly.value) return;
    final prev = bucket.value;
    if (prev == null || prev.srEnabled == enabled) return;

    RecallHaptics.medium();
    bucket.value = prev.copyWith(srEnabled: enabled);
    // Reflect on the in-memory notes immediately for a calm, instant UI.
    nodes.assignAll(nodes.map((n) => n.copyWith(srEnabled: enabled)).toList());

    try {
      final updated =
          await _bucketRepo.update(bucketId, {'sr_enabled': enabled});
      bucket.value = updated;
      try {
        await _nodeRepo.setBucketNodesSrEnabled(bucketId, enabled);
      } on RepoException {
        // Keep server consistent: undo the bucket flag if note bulk-apply fails.
        await _bucketRepo.update(bucketId, {'sr_enabled': prev.srEnabled});
        rethrow;
      }
      await _reloadNodes();
      _refreshBucketsList();
    } on RepoException catch (e, st) {
      bucket.value = prev;
      await _reloadNodes();
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  // ── Swipe-to-delete a single note ──

  /// One-time animated swipe hint per bucket. True until the user has either
  /// seen the hint or performed a swipe-delete in this bucket.
  final RxBool showSwipeHint = false.obs;

  /// Decides whether to show the swipe hint (only when notes exist and it hasn't
  /// been seen for this bucket). Called after nodes load.
  Future<void> _maybeShowSwipeHint() async {
    if (readOnly.value || !hasNodes) return;
    if (await _local.coachSeen(_swipeHintKey)) return;
    showSwipeHint.value = true;
  }

  String get _swipeHintKey => 'swipe_delete:$bucketId';

  /// Dismisses the hint and remembers it so it never shows again for this bucket.
  Future<void> dismissSwipeHint() async {
    if (!showSwipeHint.value) return;
    showSwipeHint.value = false;
    await _local.markCoachSeen(_swipeHintKey);
  }

  /// Soft-deletes one note (swipe → confirm). Optimistically removes it from the
  /// list; restores it if the server call fails. Also retires the swipe hint.
  Future<bool> onDeleteNodeSwiped(Node node) async {
    RecallHaptics.medium();
    final index = nodes.indexWhere((n) => n.id == node.id);
    if (index < 0) return false;
    final removed = nodes[index];
    nodes.removeAt(index);
    await dismissSwipeHint();
    try {
      await _nodeRepo.softDelete(node.id);
      return true;
    } on RepoException catch (e, st) {
      // Restore on failure so the note never silently vanishes.
      nodes.insert(index.clamp(0, nodes.length), removed);
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
      return false;
    }
  }

  // ── Delete ──

  Future<void> onDeleteConfirmed() async {
    RecallHaptics.heavy();
    try {
      await _bucketRepo.softDelete(bucketId);
      Get.back();
    } on RepoException catch (e, st) {
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  // ── Navigation ──

  Future<void> onNodeTap(Node node) async {
    RecallHaptics.selection();
    await Get.toNamed(Routes.node, arguments: {'node_id': node.id});
    await _reloadNodes();
  }

  Future<void> onAddNodeTap() async {
    RecallHaptics.light();
    await Get.toNamed(Routes.nodeAdd, arguments: {'bucket_id': bucketId});
    await _reloadNodes();
  }

  /// Opens the dedicated Bucket config surface (reuses this live controller).
  Future<void> openBucketConfig() async {
    RecallHaptics.selection();
    await Get.toNamed(Routes.bucketConfig, arguments: {'bucket_id': bucketId});
  }

  /// Silently refreshes the node list + mastery after returning from add/edit
  /// (no loading flicker), so newly saved or edited nodes appear immediately.
  Future<void> _reloadNodes() async {
    if (bucketId.isEmpty) return;
    try {
      final results = await Future.wait([
        _nodeRepo.fetchByBucket(bucketId, forceRemote: true),
        _bucketRepo.fetchMastery(bucketId),
      ]);
      nodes.assignAll(results[0] as List<Node>);
      _applySorting();
      mastery.value = (results[1] as double?) ?? mastery.value;
    } on RepoException catch (e, st) {
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  // ── Helpers ──

  String relativeTime(DateTime? dt) {
    if (dt == null) return 'New';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  String nodeDueLabel(DateTime? dueAt) {
    if (dueAt == null) return 'New';
    final diff = DateTime.now().difference(dueAt);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Due today';
      if (days == 1) return 'Due tomorrow';
      return 'In ${days}d';
    }
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due 1d ago';
    return 'Due ${diff.inDays}d ago';
  }
}
