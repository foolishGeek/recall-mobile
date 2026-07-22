import 'dart:async';

import 'package:flutter/widgets.dart' hide Stack;
import 'package:get/get.dart' hide Node;

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/coach_keys.dart';
import '../../../core/utils/note_links.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/stack_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/metrics_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/supabase_service.dart';
import '../../shell/controller/shell_controller.dart';

typedef IntervalPreview = Map<String, dynamic>;

class ReviewController extends BaseController {
  final _auth = Get.find<AuthService>();
  final _stackRepo = Get.find<StackRepository>();
  final _reviewRepo = Get.find<ReviewRepository>();
  final _nodeRepo = Get.find<NodeRepository>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _aiRepo = Get.find<AiRepository>();
  final _supabase = Get.find<SupabaseService>();
  final _metrics = Get.find<MetricsService>();
  final _local = Get.find<LocalStore>();

  final Rxn<Stack> stack = Rxn<Stack>();
  final RxList<StackItem> items = <StackItem>[].obs;
  final RxMap<String, Node> nodes = <String, Node>{}.obs;
  final RxMap<String, String> bucketNames = <String, String>{}.obs;

  // Attachments for any node that has files (modern notes are type=text),
  // plus signed URLs keyed by asset id.
  final RxMap<String, List<NodeAsset>> nodeAssets =
      <String, List<NodeAsset>>{}.obs;
  final RxMap<String, String> signedUrls = <String, String>{}.obs;
  /// LINKED / WATCH previews from markdown URLs, keyed by nodeId.
  final RxMap<String, List<LinkPreview>> contentLinks =
      <String, List<LinkPreview>>{}.obs;
  final RxMap<String, IntervalPreview> intervalPreviews =
      <String, IntervalPreview>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isCompleting = false.obs;
  final RxBool isAnimating = false.obs;
  final Rxn<ReviewGrade> dragGrade = Rxn<ReviewGrade>();

  /// One-time tip explaining review grades (seen via [CoachKeys.reviewGrades]).
  final RxBool showGradesCoachTip = false.obs;

  int get totalItems => items.length;
  int get doneItems => currentIndex.value;
  bool get isLastCard =>
      items.isNotEmpty && currentIndex.value == totalItems - 1;

  bool get canRate => !isAnimating.value && !isCompleting.value;

  StackItem? get currentItem =>
      currentIndex.value < items.length ? items[currentIndex.value] : null;

  Node? get currentNode {
    final item = currentItem;
    return item != null ? nodes[item.nodeId] : null;
  }

  String get currentBucketName {
    final node = currentNode;
    if (node == null) return '';
    return bucketNames[node.bucketId] ?? '';
  }

  IntervalPreview? get currentPreview {
    final item = currentItem;
    return item != null ? intervalPreviews[item.nodeId] : null;
  }

  DateTime? _cardShownAt;
  bool _rateLocked = false;

  static const Set<String> _shellRoutes = {
    Routes.today,
    Routes.buckets,
    Routes.quiz,
    Routes.insights,
    Routes.you,
  };

  /// Leaves review by popping back to the live shell instead of wiping the
  /// stack. `offAllNamed` destroyed the shell (blank tabs) and left a single
  /// route (system back exited the app); popping keeps the shell alive so tabs
  /// and back behave normally. Fall back to `offAllNamed` only when review is
  /// the sole route (deep-link / orphan entry).
  void _exitToShell() {
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().onTabSelected(RecallTab.today);
    }
    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      Get.until((Route<dynamic> route) =>
          _shellRoutes.contains(route.settings.name));
    } else {
      Get.offAllNamed(Routes.today);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      _exitToShell();
      return;
    }

    setLoading();

    try {
      final activeStack =
          await _stackRepo.fetchActive(userId, forceRemote: true);
      if (activeStack == null || activeStack.status != StackStatus.active) {
        _exitToShell();
        return;
      }

      stack.value = activeStack;
      final stackItems =
          await _stackRepo.fetchItems(activeStack.id, forceRemote: true);
      items.assignAll(stackItems);

      if (items.isEmpty) {
        _exitToShell();
        return;
      }

      final alreadyReviewed = items.where((i) => i.reviewed).length;
      currentIndex.value = alreadyReviewed;

      if (currentIndex.value >= items.length) {
        _exitToShell();
        return;
      }

      await _fetchNodesAndBuckets();
      _prefetchIntervals();
      _cardShownAt = DateTime.now();
      setSuccess();
      unawaited(_maybeShowGradesCoachTip());
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  Future<void> _maybeShowGradesCoachTip() async {
    if (await _local.coachSeen(CoachKeys.reviewGrades)) return;
    if (isClosed) return;
    showGradesCoachTip.value = true;
  }

  Future<void> dismissGradesCoachTip() async {
    if (!showGradesCoachTip.value) return;
    showGradesCoachTip.value = false;
    await _local.markCoachSeen(CoachKeys.reviewGrades);
  }

  Future<void> _fetchNodesAndBuckets() async {
    final nodeIds = items.map((i) => i.nodeId).toSet();
    final bucketIds = <String>{};

    // Load every stack node before the first card paints — never swipe on a
    // half-empty map.
    await Future.wait([
      for (final nodeId in nodeIds) _loadOneNode(nodeId, bucketIds),
    ]);

    await Future.wait([
      for (final bucketId in bucketIds)
        if (!bucketNames.containsKey(bucketId)) _loadBucketName(bucketId),
    ]);
  }

  Future<void> _loadOneNode(String nodeId, Set<String> bucketIds) async {
    var node = await _nodeRepo.fetchById(nodeId, forceRemote: true);
    // If remote came back empty-bodied but cache has text, prefer cache.
    if (node != null && _nodeLooksEmpty(node)) {
      final cached = await _nodeRepo.fetchById(nodeId);
      if (cached != null && !_nodeLooksEmpty(cached)) {
        node = cached;
      }
    }
    if (node == null) return;
    nodes[nodeId] = node;
    bucketIds.add(node.bucketId);
    await _loadAssets(node);
    _loadContentLinks(node);
  }

  bool _nodeLooksEmpty(Node n) {
    final md = (n.markdown ?? '').trim();
    final et = (n.extractedText ?? '').trim();
    return md.isEmpty && et.isEmpty && (n.title.trim().isEmpty);
  }

  Future<void> _loadBucketName(String bucketId) async {
    final bucket = await _bucketRepo.fetchById(bucketId);
    if (bucket != null) bucketNames[bucketId] = bucket.name;
  }

  /// Loads and signs attachments for any node. Best-effort: failure leaves the
  /// card on text / link cards instead of failing the session.
  Future<void> _loadAssets(Node node) async {
    try {
      final assets = await _nodeRepo.fetchAssets(node.id);
      if (assets.isEmpty) return;
      nodeAssets[node.id] = assets;
      for (final asset in assets) {
        if (asset.storagePath.isEmpty) continue;
        try {
          signedUrls[asset.id] =
              await _nodeRepo.signAssetUrl(asset.storagePath, asset.mimeType);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Seeds LINKED / WATCH cards from markdown (and legacy `url`), then enriches
  /// via `link-preview` in the background so the card is never blank waiting.
  void _loadContentLinks(Node n) {
    final seen = <String>{};
    final urls = <String>[];

    final structuredUrl = n.linkPreview?.canonicalUrl;
    if ((n.type == NodeType.link || n.type == NodeType.youtube) &&
        n.url != null &&
        n.url!.trim().isNotEmpty &&
        (structuredUrl == null || structuredUrl.isEmpty)) {
      final u = n.url!.trim();
      if (seen.add(u)) urls.add(u);
    }

    for (final u in standaloneUrls(n.markdown)) {
      if (u == structuredUrl) continue;
      if (seen.add(u)) urls.add(u);
      if (urls.length >= 6) break;
    }

    // Also pick up inline http(s) URLs in prose (capped).
    if (urls.length < 6) {
      final md = n.markdown;
      if (md != null && md.trim().isNotEmpty) {
        for (final match in RegExp(r'https?://[^\s)\]<>"]+').allMatches(md)) {
          var url = match.group(0)!;
          url = url.replaceAll(RegExp(r'[.,;:!?]+$'), '');
          if (url == structuredUrl) continue;
          if (seen.add(url)) urls.add(url);
          if (urls.length >= 6) break;
        }
      }
    }

    if (urls.isEmpty) {
      contentLinks.remove(n.id);
      return;
    }

    final seeds = [for (final u in urls) _seedPreview(u)];
    contentLinks[n.id] = seeds;

    for (var i = 0; i < urls.length; i++) {
      unawaited(_enrichLink(n.id, urls[i], i));
    }
  }

  LinkPreview _seedPreview(String url) {
    return LinkPreview(canonicalUrl: url, videoId: _youtubeId(url));
  }

  static String? _youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments.first == 'embed' ||
              uri.pathSegments.first == 'shorts')) {
        return uri.pathSegments[1];
      }
    }
    return null;
  }

  Future<void> _enrichLink(String nodeId, String url, int index) async {
    try {
      final preview =
          await _aiRepo.linkPreview(url).timeout(const Duration(seconds: 6));
      var enriched =
          preview.canonicalUrl == null || preview.canonicalUrl!.isEmpty
              ? preview.copyWith(canonicalUrl: url)
              : preview;
      if (enriched.videoId == null || enriched.videoId!.isEmpty) {
        final vid = _youtubeId(url);
        if (vid != null) enriched = enriched.copyWith(videoId: vid);
      }
      final list = contentLinks[nodeId];
      if (list == null || index >= list.length) return;
      final next = List<LinkPreview>.from(list);
      next[index] = enriched;
      contentLinks[nodeId] = next;
    } catch (_) {
      // Keep the seed preview already shown.
    }
  }

  /// Skip a missing node without crashing the session.
  void skipMissingNode() {
    if (!canRate || _rateLocked) return;
    _rateLocked = true;
    isAnimating.value = true;
    _advance();
  }

  void _prefetchIntervals() {
    final end = (currentIndex.value + 2).clamp(0, items.length);
    for (var i = currentIndex.value; i < end; i++) {
      final nodeId = items[i].nodeId;
      if (!intervalPreviews.containsKey(nodeId)) {
        _fetchInterval(nodeId);
      }
    }
  }

  Future<void> _fetchInterval(String nodeId) async {
    try {
      final result = await _supabase.rpc(
        'preview_due_interval_rpc',
        params: {'node_id': nodeId},
      );
      if (result is Map) {
        intervalPreviews[nodeId] = Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Non-critical; buttons show without captions
    }
  }

  String intervalLabel(ReviewGrade grade) {
    final preview = currentPreview;
    if (preview == null) return '';
    final gradeData = preview[grade.wire];
    if (gradeData is Map) return gradeData['label']?.toString() ?? '';
    return '';
  }

  void onThrowStarted() {
    isAnimating.value = true;
    dragGrade.value = null;
  }

  void onDragGradeChanged(ReviewGrade? grade) {
    dragGrade.value = grade;
  }

  Future<void> onRate(ReviewGrade grade) async {
    if (isCompleting.value || _rateLocked) return;
    unawaited(dismissGradesCoachTip());

    final item = currentItem;
    final node = currentNode;
    final s = stack.value;
    if (item == null || node == null || s == null) {
      isAnimating.value = false;
      return;
    }

    _rateLocked = true;
    isAnimating.value = true;
    dragGrade.value = null;
    _fireHaptic(grade);

    final responseMs = _cardShownAt != null
        ? DateTime.now().difference(_cardShownAt!).inMilliseconds
        : 0;

    final clientUuid = '${DateTime.now().microsecondsSinceEpoch}';
    final idempotencyKey = '${s.id}:${node.id}:$clientUuid';

    final review = Review(
      id: clientUuid,
      userId: _auth.currentUserId!,
      nodeId: node.id,
      stackId: s.id,
      source: ReviewSource.stack,
      idempotencyKey: idempotencyKey,
      grade: grade,
      responseMs: responseMs,
      clientTimestamp: DateTime.now().toUtc(),
    );

    unawaited(_reviewRepo.append(review).then((result) {
      if (result.node != null) {
        nodes[node.id] = result.node!;
      }
    }));

    _advance();
  }

  void _advance() {
    final nextIdx = currentIndex.value + 1;

    if (nextIdx >= items.length) {
      isAnimating.value = false;
      _rateLocked = false;
      _onComplete();
      return;
    }

    currentIndex.value = nextIdx;
    _cardShownAt = DateTime.now();
    _prefetchIntervals();
    // Brief delay so the new keyed card mounts before accepting input.
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (!isClosed) {
        isAnimating.value = false;
        _rateLocked = false;
      }
    });
  }

  void _fireHaptic(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.again:
        RecallHaptics.selection();
        break;
      case ReviewGrade.hard:
        RecallHaptics.light();
        break;
      case ReviewGrade.good:
      case ReviewGrade.easy:
        RecallHaptics.medium();
        break;
    }
  }

  Future<void> _onComplete() async {
    if (isCompleting.value) return;
    isCompleting.value = true;
    RecallHaptics.heavy();

    try {
      final result = await _supabase.rpc(
        'complete_stack_rpc',
        params: {'p_stack_id': stack.value!.id},
      );

      final map =
          result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
      final cooling = map['cooling_buckets'];

      if (cooling is List && cooling.isNotEmpty) {
        final first = cooling.first;
        final name = first['name'] ?? '';
        final days = first['cooldown_days'] ?? 0;
        Get.snackbar(
          'Session complete',
          'Bucket "$name" cooling for $days days',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }

      _metrics.markStackCompleted(stack.value!.id);

      await Future.delayed(const Duration(milliseconds: 400));
      _exitToShell();
    } on RepoException catch (_) {
      await _stackRepo.updateStatus(stack.value!.id, StackStatus.completed);
      _metrics.markStackCompleted(stack.value!.id);
      _exitToShell();
    } finally {
      isCompleting.value = false;
      isAnimating.value = false;
    }
  }

  Future<void> onAbandon() async {
    final s = stack.value;
    if (s == null) {
      _exitToShell();
      return;
    }

    try {
      // Prefer abandon_stack_rpc — clears stuck cooldown when due/new remain.
      await _stackRepo.abandon(s.id);
    } catch (_) {
      // Offline / older backend: mark abandoned only. Cooldown is no longer
      // set at generate time (00033), so Today won't go empty mid-session.
      try {
        await _stackRepo.updateStatus(s.id, StackStatus.abandoned);
      } catch (_) {
        // best-effort; navigate regardless
      }
    }
    _exitToShell();
  }
}
