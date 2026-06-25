import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';

class BucketController extends BaseController {
  BucketController(
    AuthService _,
    this._bucketRepo,
    this._nodeRepo,
    this._aiRepo,
    this._tierService,
  );

  final BucketRepository _bucketRepo;
  final NodeRepository _nodeRepo;
  final AiRepository _aiRepo;
  final TierService _tierService;

  late final String bucketId;
  final Rxn<Bucket> bucket = Rxn<Bucket>();
  final RxDouble mastery = 0.0.obs;
  final RxList<Node> nodes = <Node>[].obs;
  final RxBool readOnly = false.obs;
  final RxBool isSummarizing = false.obs;
  final Rxn<SummarizeResult> summaryResult = Rxn<SummarizeResult>();
  final RxnString summaryError = RxnString();

  // AI model labels from app_config
  final RxString aiModelLabel = ''.obs;

  TierGate get gate => _tierService.gate;
  bool get hasNodes => nodes.isNotEmpty;
  int get nodeCount => nodes.length;

  HeatSummary get heatSummary => bucket.value?.heatSummary ?? HeatSummary.empty;

  // Config state
  int get coolingIndex {
    final cp = bucket.value?.coolingPeriod ?? '';
    if (cp.contains('14')) return 0;
    if (cp.contains('60')) return 2;
    return 1; // 30d default
  }

  int get frequencyIndex {
    switch (bucket.value?.frequency ?? 'daily') {
      case '3xwk':
        return 1;
      case 'weekly':
        return 2;
      default:
        return 0;
    }
  }

  int get dailyCapIndex {
    const stops = [5, 10, 15, 20, 30];
    final cap = bucket.value?.dailyCap;
    if (cap == null) return 2; // default 15
    final idx = stops.indexOf(cap);
    return idx >= 0 ? idx : 2;
  }

  static const coolingValues = ['14 days', '30 days', '60 days'];
  static const frequencyValues = ['daily', '3xwk', 'weekly'];
  static const capStops = [5, 10, 15, 20, 30];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    bucketId = args['bucket_id'] as String? ?? '';
    readOnly.value = args['read_only'] as bool? ?? false;
    _loadData();
    _loadModelLabel();
  }

  Future<void> _loadData() async {
    if (bucketId.isEmpty) {
      setError('No bucket ID provided.');
      return;
    }
    setLoading();
    try {
      final results = await Future.wait([
        _bucketRepo.fetchById(bucketId),
        _bucketRepo.fetchMastery(bucketId),
        _nodeRepo.fetchByBucket(bucketId),
      ]);
      final loadedBucket = results[0] as Bucket?;
      if (loadedBucket == null) {
        setError('Bucket not found.');
        return;
      }
      bucket.value = loadedBucket;
      mastery.value = (results[1] as double?) ?? 0.0;
      nodes.assignAll(results[2] as List<Node>);
      setSuccess();
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  Future<void> _loadModelLabel() async {
    try {
      final map = await _bucketRepo.fetchAiModelLabels();
      if (gate.isPremium) {
        aiModelLabel.value = map['ai_model_premium'] ?? 'claude-sonnet';
      } else {
        aiModelLabel.value = map['ai_model_free'] ?? 'gemini-1.5-flash';
      }
    } catch (_) {
      aiModelLabel.value = gate.isPremium ? 'claude-sonnet' : 'gemini-1.5-flash';
    }
  }

  Future<void> reload() async {
    await _loadData();
  }

  // ── Config writes (optimistic + revert on failure) ──

  Future<void> onCoolingChanged(int index) async {
    if (readOnly.value) return;
    RecallHaptics.selection();
    final prev = bucket.value;
    if (prev == null) return;

    final newVal = coolingValues[index];
    bucket.value = prev.copyWith(coolingPeriod: newVal);

    try {
      final updated =
          await _bucketRepo.update(bucketId, {'cooling_period': newVal});
      bucket.value = updated;
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  Future<void> onFrequencyChanged(int index) async {
    if (readOnly.value) return;
    RecallHaptics.selection();
    final prev = bucket.value;
    if (prev == null) return;

    final newVal = frequencyValues[index];
    bucket.value = prev.copyWith(frequency: newVal);

    try {
      final updated =
          await _bucketRepo.update(bucketId, {'frequency': newVal});
      bucket.value = updated;
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
    }
  }

  Future<void> onDailyCapChanged(int index) async {
    if (readOnly.value) return;
    RecallHaptics.selection();
    final prev = bucket.value;
    if (prev == null) return;

    final newCap = capStops[index];
    bucket.value = prev.copyWith(dailyCap: newCap);

    try {
      final updated =
          await _bucketRepo.update(bucketId, {'daily_cap': newCap});
      bucket.value = updated;
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
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

  // ── Rename ──

  Future<void> onRename(String newName) async {
    if (newName.trim().isEmpty) return;
    final prev = bucket.value;
    if (prev == null) return;

    bucket.value = prev.copyWith(name: newName.trim());
    try {
      final updated =
          await _bucketRepo.update(bucketId, {'name': newName.trim()});
      bucket.value = updated;
    } on RepoException catch (e, st) {
      bucket.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'bucket_detail'));
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

  void onNodeTap(Node node) {
    RecallHaptics.selection();
    Get.toNamed(Routes.node, arguments: {'node_id': node.id});
  }

  void onAddNodeTap() {
    RecallHaptics.light();
    Get.toNamed(Routes.nodeAdd, arguments: {'bucket_id': bucketId});
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
}
