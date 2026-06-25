import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:get/get.dart' hide Node;

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/stack_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/supabase_service.dart';

typedef IntervalPreview = Map<String, dynamic>;

class ReviewController extends BaseController with GetTickerProviderStateMixin {
  final _auth = Get.find<AuthService>();
  final _stackRepo = Get.find<StackRepository>();
  final _reviewRepo = Get.find<ReviewRepository>();
  final _nodeRepo = Get.find<NodeRepository>();
  final _bucketRepo = Get.find<BucketRepository>();
  final _supabase = Get.find<SupabaseService>();

  final Rxn<Stack> stack = Rxn<Stack>();
  final RxList<StackItem> items = <StackItem>[].obs;
  final RxMap<String, Node> nodes = <String, Node>{}.obs;
  final RxMap<String, String> bucketNames = <String, String>{}.obs;
  final RxMap<String, IntervalPreview> intervalPreviews =
      <String, IntervalPreview>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isCompleting = false.obs;
  final RxBool isAnimating = false.obs;

  int get totalItems => items.length;
  int get doneItems => currentIndex.value;
  bool get isLastCard => currentIndex.value == totalItems - 1;

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

  late final AnimationController throwController;
  late final AnimationController nextCardController;
  late final AnimationController checkmarkController;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _loadSession();
  }

  void _initAnimations() {
    throwController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    nextCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  Future<void> _loadSession() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      Get.offAllNamed(Routes.today);
      return;
    }

    setLoading();

    try {
      final activeStack = await _stackRepo.fetchActive(userId, forceRemote: true);
      if (activeStack == null || activeStack.status != StackStatus.active) {
        Get.offAllNamed(Routes.today);
        return;
      }

      stack.value = activeStack;
      final stackItems = await _stackRepo.fetchItems(activeStack.id, forceRemote: true);
      items.assignAll(stackItems);

      if (items.isEmpty) {
        Get.offAllNamed(Routes.today);
        return;
      }

      final alreadyReviewed = items.where((i) => i.reviewed).length;
      currentIndex.value = alreadyReviewed;

      if (currentIndex.value >= items.length) {
        Get.offAllNamed(Routes.today);
        return;
      }

      await _fetchNodesAndBuckets();
      _prefetchIntervals();
      _cardShownAt = DateTime.now();
      setSuccess();
    } on RepoException catch (e) {
      setError(e.message);
    }
  }

  Future<void> _fetchNodesAndBuckets() async {
    final nodeIds = items.map((i) => i.nodeId).toSet();
    final bucketIds = <String>{};

    for (final nodeId in nodeIds) {
      final node = await _nodeRepo.fetchById(nodeId);
      if (node != null) {
        nodes[nodeId] = node;
        bucketIds.add(node.bucketId);
      }
    }

    for (final bucketId in bucketIds) {
      if (!bucketNames.containsKey(bucketId)) {
        final bucket = await _bucketRepo.fetchById(bucketId);
        if (bucket != null) {
          bucketNames[bucketId] = bucket.name;
        }
      }
    }
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

  Future<void> onRate(ReviewGrade grade) async {
    if (isAnimating.value || isCompleting.value) return;

    final item = currentItem;
    final node = currentNode;
    final s = stack.value;
    if (item == null || node == null || s == null) return;

    _fireHaptic(grade);

    final responseMs = _cardShownAt != null
        ? DateTime.now().difference(_cardShownAt!).inMilliseconds
        : 0;

    final clientUuid =
        '${DateTime.now().microsecondsSinceEpoch}';
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
      _onComplete();
      return;
    }

    currentIndex.value = nextIdx;
    _cardShownAt = DateTime.now();
    _prefetchIntervals();
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

      final map = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
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

      await Future.delayed(const Duration(milliseconds: 400));
      Get.offAllNamed(Routes.today);
    } on RepoException catch (_) {
      await _stackRepo.updateStatus(stack.value!.id, StackStatus.completed);
      Get.offAllNamed(Routes.today);
    } finally {
      isCompleting.value = false;
    }
  }

  Future<void> onAbandon() async {
    final s = stack.value;
    if (s == null) {
      Get.offAllNamed(Routes.today);
      return;
    }

    try {
      await _stackRepo.updateStatus(s.id, StackStatus.abandoned);
    } catch (_) {
      // best-effort; navigate regardless
    }
    Get.offAllNamed(Routes.today);
  }

  @override
  void onClose() {
    throwController.dispose();
    nextCardController.dispose();
    checkmarkController.dispose();
    super.onClose();
  }
}
