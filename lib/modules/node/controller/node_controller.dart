import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/neo_chip.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';

class NodeController extends BaseController {
  NodeController(
    this._auth,
    this._nodeRepo,
    this._aiRepo,
    this._profileRepo,
    this._tierService,
  );

  final AuthService _auth;
  final NodeRepository _nodeRepo;
  final AiRepository _aiRepo;
  final ProfileRepository _profileRepo;
  final TierService _tierService;

  late final String nodeId;

  // ── Reactive state ──
  final Rxn<Node> node = Rxn<Node>();
  final RxList<NodeAsset> assets = <NodeAsset>[].obs;
  final RxList<Tag> tags = <Tag>[].obs;
  final RxnString bucketName = RxnString();
  final RxDouble heatPct = 0.0.obs;
  final RxBool hasReviews = false.obs;

  // Signed URLs keyed by asset id.
  final RxMap<String, String> signedUrls = <String, String>{}.obs;

  // Rich previews for links found inside the markdown body (LINKED / WATCH
  // cards). Populated asynchronously after the node loads.
  final RxList<LinkPreview> contentLinks = <LinkPreview>[].obs;

  // AI evaluation state.
  final Rxn<AiEvaluation> evaluation = Rxn<AiEvaluation>();
  final RxBool isEvalLoading = false.obs;
  final RxnString evalError = RxnString();

  // AI model label from app_config.
  final RxString aiModelLabel = ''.obs;
  final RxInt overviewsUsed = 0.obs;

  // Ask AI state.
  final RxBool isAskingAi = false.obs;
  final Rxn<RagChatResult> ragResult = Rxn<RagChatResult>();
  final RxnString ragError = RxnString();

  // ── Derived getters ──
  TierGate get gate => _tierService.gate;
  bool get showAiPanel => !gate.aiOverviewBlocked;
  bool get showAskAi => !gate.aiDisabled;
  bool get overviewLocked =>
      gate.aiOverviewQuotaExhausted(overviewsUsed: overviewsUsed.value);

  String get nodeTypeLabel {
    switch (node.value?.type ?? NodeType.text) {
      case NodeType.text:
        return 'NOTE';
      case NodeType.link:
        return 'LINK';
      case NodeType.youtube:
        return 'YOUTUBE';
      case NodeType.pdf:
        return 'PDF';
      case NodeType.image:
        return 'IMAGE';
    }
  }

  String get editedAgoLabel => _relativeTime(node.value?.updatedAt);

  String get dueAgoLabel {
    final due = node.value?.dueAt;
    if (due == null) return 'New';
    final diff = DateTime.now().difference(due);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Due today';
      if (days == 1) return 'Due tomorrow';
      return 'Due in ${days}d';
    }
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due 1 day ago';
    return 'Due ${diff.inDays} days ago';
  }

  int get qualityScore => evaluation.value?.qualityScore ?? 0;

  String get qualityScoreDisplay => '$qualityScore/100';

  double get qualityProgress => qualityScore / 100.0;

  String get suggestedComfortLabel =>
      comfortLabel(evaluation.value?.suggestedComfort ?? 50);

  NeoLevel get suggestedComfortLevel =>
      _comfortLevel(evaluation.value?.suggestedComfort ?? 50);

  String? get evalFeedback => evaluation.value?.feedback;

  String get overviewQuotaLabel => '${overviewsUsed.value} / 2';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    nodeId = args['node_id'] as String? ?? '';
    _loadData();
    _trackEvent('node_detail_viewed', {'node_id': nodeId});
  }

  // ── Data loading ──

  Future<void> _loadData() async {
    if (nodeId.isEmpty) {
      setError('No node ID provided.');
      return;
    }
    setLoading();
    try {
      final results = await Future.wait([
        _nodeRepo.fetchById(nodeId),           // 0
        _nodeRepo.fetchAssets(nodeId),          // 1
        _nodeRepo.fetchTagsForNode(nodeId),     // 2
        _nodeRepo.fetchHeatPct(nodeId),         // 3
        _nodeRepo.hasReviews(nodeId),           // 4
        _aiRepo.fetchLatestEvaluation(nodeId),  // 5
        _loadProfile(),                         // 6
      ]);

      final loadedNode = results[0] as Node?;
      if (loadedNode == null) {
        setError('Node not found.');
        return;
      }
      node.value = loadedNode;
      assets.assignAll(results[1] as List<NodeAsset>);
      tags.assignAll(results[2] as List<Tag>);
      heatPct.value = results[3] as double;
      hasReviews.value = results[4] as bool;
      evaluation.value = results[5] as AiEvaluation?;

      _loadBucketName(loadedNode.bucketId);
      _loadModelLabel();
      _signAssetUrls();
      _loadContentLinks(loadedNode);

      if (evaluation.value == null && showAiPanel && !overviewLocked) {
        _triggerEvaluate();
      }

      setSuccess();
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  Future<void> _loadProfile() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      final profile = await _profileRepo.fetchProfile(userId);
      if (profile != null) {
        overviewsUsed.value = profile.aiOverviewsMonth;
      }
    } catch (_) {}
  }

  Future<void> _loadBucketName(String bucketId) async {
    try {
      bucketName.value = await _nodeRepo.fetchBucketName(bucketId);
    } catch (_) {}
  }

  Future<void> _loadModelLabel() async {
    try {
      final map = await _nodeRepo.fetchAiModelLabels();
      aiModelLabel.value = gate.isPremium
          ? (map['ai_model_premium'] ?? 'claude-sonnet')
          : (map['ai_model_free'] ?? 'gemini-1.5-flash');
    } catch (_) {
      aiModelLabel.value =
          gate.isPremium ? 'claude-sonnet' : 'gemini-1.5-flash';
    }
  }

  Future<void> _signAssetUrls() async {
    for (final asset in assets) {
      if (asset.storagePath.isEmpty) continue;
      try {
        final url =
            await _nodeRepo.signAssetUrl(asset.storagePath, asset.mimeType);
        signedUrls[asset.id] = url;
      } catch (_) {}
    }
  }

  Future<void> reload() async => _loadData();

  // ── Content link previews (links written inside the markdown body) ──

  static final _urlRegex = RegExp(r'https?://[^\s)\]<>"]+');

  /// Finds URLs in the node's markdown and fetches a rich preview for each so
  /// they render as LINKED / WATCH cards (matching the design), instead of
  /// staying as plain inline text. Runs in the background; cards appear as the
  /// previews resolve. Excludes the node's primary structured link preview.
  Future<void> _loadContentLinks(Node n) async {
    contentLinks.clear();
    final md = n.markdown;
    if (md == null || md.trim().isEmpty) return;

    final primaryUrl = n.linkPreview?.canonicalUrl;
    final seen = <String>{};
    final urls = <String>[];
    for (final match in _urlRegex.allMatches(md)) {
      var url = match.group(0)!;
      // Strip trailing punctuation that commonly hugs a URL in prose.
      url = url.replaceAll(RegExp(r'[.,;:!?]+$'), '');
      if (url == primaryUrl) continue;
      if (seen.add(url)) urls.add(url);
      if (urls.length >= 6) break; // keep the screen + network bounded
    }
    if (urls.isEmpty) return;

    final resolved = <LinkPreview>[];
    for (final url in urls) {
      try {
        final preview = await _aiRepo.linkPreview(url);
        resolved.add(
          preview.canonicalUrl == null || preview.canonicalUrl!.isEmpty
              ? preview.copyWith(canonicalUrl: url)
              : preview,
        );
      } catch (_) {
        // Skip links we can't preview (offline, blocked, etc.).
      }
    }
    contentLinks.assignAll(resolved);
  }

  // ── Chip cycling ──

  static const _priorityLabels = ['LOW', 'LOW', 'MED', 'HIGH', 'HIGH'];
  static const _difficultyLabels = ['EASY', 'EASY', 'MED', 'HARD', 'HARD'];

  String priorityLabel(int val) => _priorityLabels[(val - 1).clamp(0, 4)];
  String difficultyLabel(int val) => _difficultyLabels[(val - 1).clamp(0, 4)];

  static String comfortLabel(int val) {
    if (val <= 33) return 'LOW';
    if (val <= 66) return 'SO-SO';
    return 'COMFY';
  }

  NeoLevel priorityLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  NeoLevel difficultyLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  static NeoLevel _comfortLevel(int val) {
    if (val <= 33) return NeoLevel.high;
    if (val <= 66) return NeoLevel.medium;
    return NeoLevel.low;
  }

  NeoLevel comfortLevelFor(int val) => _comfortLevel(val);

  void onPriorityTap() {
    RecallHaptics.light();
    final n = node.value;
    if (n == null) return;
    final next = (n.priority % 5) + 1;
    _updateNodeField('priority', next, n.copyWith(priority: next));
  }

  void onDifficultyTap() {
    RecallHaptics.light();
    final n = node.value;
    if (n == null) return;
    final next = (n.difficulty % 5) + 1;
    _updateNodeField('difficulty', next, n.copyWith(difficulty: next));
  }

  void onComfortTap() {
    if (hasReviews.value) return;
    RecallHaptics.light();
    final n = node.value;
    if (n == null) return;
    int next;
    if (n.comfort <= 33) {
      next = 50;
    } else if (n.comfort <= 66) {
      next = 80;
    } else {
      next = 20;
    }
    _updateNodeField('comfort', next, n.copyWith(comfort: next));
  }

  Future<void> _updateNodeField(
    String field,
    dynamic value,
    Node optimistic,
  ) async {
    final prev = node.value;
    node.value = optimistic;
    try {
      final updated = await _nodeRepo.update(nodeId, {field: value});
      node.value = updated;
    } on RepoException catch (e, st) {
      node.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    }
  }

  // ── AI Evaluation ──

  Future<void> _triggerEvaluate() async {
    if (!showAiPanel || overviewLocked) return;
    isEvalLoading.value = true;
    evalError.value = null;
    _trackEvent('ai_overview_viewed', {'node_id': nodeId});
    try {
      final result = await _aiRepo.evaluate(nodeId);
      evaluation.value = AiEvaluation(
        id: '',
        nodeId: nodeId,
        qualityScore: result.qualityScore,
        suggestedComfort: result.suggestedComfort,
        suggestedDifficulty: result.suggestedDifficulty,
        feedback: result.feedback,
        model: result.model,
      );
    } on RepoException catch (e, st) {
      evalError.value = e.message;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    } finally {
      isEvalLoading.value = false;
    }
  }

  Future<void> onRegenerateTap() async {
    await _triggerEvaluate();
  }

  void onApplySuggestion() {
    RecallHaptics.light();
    final eval = evaluation.value;
    if (eval == null) return;
    final n = node.value;
    if (n == null) return;

    final changes = <String, dynamic>{};
    Node updated = n;

    if (eval.suggestedComfort != null && !hasReviews.value) {
      changes['comfort'] = eval.suggestedComfort!;
      updated = updated.copyWith(comfort: eval.suggestedComfort!);
    }
    if (eval.suggestedDifficulty != null) {
      changes['difficulty'] = eval.suggestedDifficulty!;
      updated = updated.copyWith(difficulty: eval.suggestedDifficulty!);
    }
    if (changes.isNotEmpty) {
      _updateNodeField(changes.keys.first, changes.values.first, updated);
    }
  }

  // ── Ask AI ──

  Future<void> onAskAiSend(String question) async {
    if (question.trim().isEmpty) return;
    RecallHaptics.selection();
    isAskingAi.value = true;
    ragError.value = null;
    _trackEvent('ask_ai_sent', {'node_id': nodeId});
    try {
      ragResult.value = await _aiRepo.ragChat(
        question: question.trim(),
        nodeIds: [nodeId],
      );
    } on RepoException catch (e, st) {
      ragError.value = e.message;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    } finally {
      isAskingAi.value = false;
    }
  }

  void clearRagResult() {
    ragResult.value = null;
    ragError.value = null;
  }

  // ── Navigation ──

  void onEditTap() {
    RecallHaptics.selection();
    Get.toNamed(Routes.nodeAdd, arguments: {
      'node_id': nodeId,
      'bucket_id': node.value?.bucketId,
    });
  }

  void onLinkTap() => openUrl(node.value?.linkPreview?.canonicalUrl);

  void onYoutubeTap() => openYoutube(node.value?.linkPreview?.videoId);

  /// Opens an arbitrary link preview URL (used by both the primary preview and
  /// links surfaced from the markdown body).
  void openUrl(String? url) {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void openYoutube(String? videoId) {
    if (videoId == null || videoId.isEmpty) return;
    launchUrl(
      Uri.parse('https://youtube.com/watch?v=$videoId'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ── Helpers ──

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  String pdfSizeLabel(int? bytes) {
    if (bytes == null) return 'PDF';
    if (bytes < 1024) return '$bytes B · PDF';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB · PDF';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB · PDF';
  }

  String youtubeDurationLabel(int? sec) {
    if (sec == null || sec <= 0) return '';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  /// Analytics stub — gated by opt-in. Breadcrumb-only until a full analytics
  /// service is wired (S15+). Safe to call unconditionally.
  void _trackEvent(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'analytics',
      message: name,
      data: params,
    ));
  }
}
