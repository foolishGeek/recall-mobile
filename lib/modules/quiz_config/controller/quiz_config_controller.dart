import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';

part 'quiz_config_controller_flow.dart';

class QuizConfigController extends BaseController {
  QuizConfigController(
    this._auth,
    this._quizRepo,
    this._bucketRepo,
    this._nodeRepo,
    this._profileRepo,
    this._tierService,
    this._syncStatus,
  );

  final AuthService _auth;
  final QuizRepository _quizRepo;
  final BucketRepository _bucketRepo;
  final NodeRepository _nodeRepo;
  final ProfileRepository _profileRepo;
  final TierService _tierService;
  final SyncStatusService _syncStatus;

  final promptController = TextEditingController();
  final Rx<QuizMode> mode = QuizMode.freehand.obs;
  final RxList<Bucket> buckets = <Bucket>[].obs;
  final RxList<Node> nodes = <Node>[].obs;
  final RxSet<String> selectedBucketIds = <String>{}.obs;
  final RxSet<String> selectedNodeIds = <String>{}.obs;
  final RxBool useMyNotes = true.obs;
  final RxInt questionCount = 12.obs;
  final Rx<QuizQuestionType> questionType = QuizQuestionType.mcq.obs;
  final RxInt difficulty = 3.obs;
  final RxBool timerEnabled = false.obs;
  final RxInt timerSec = 45.obs;
  final RxBool generating = false.obs;
  final RxString inlineMessage = ''.obs;
  final RxString promptText = ''.obs;

  TierGate get gate => _tierService.gate;
  bool get isOffline => _syncStatus.isOffline.value;
  bool get isFreehand => mode.value == QuizMode.freehand;
  bool get isByBucket => mode.value == QuizMode.byBucket;
  bool get isByNode => mode.value == QuizMode.byNode;

  int get selectedNodeCount {
    if (isByNode) return selectedNodeIds.length;
    if (isByBucket) {
      return nodes.where((n) => selectedBucketIds.contains(n.bucketId)).length;
    }
    return nodes.length;
  }

  bool get canGenerate {
    if (generating.value || isOffline || !gate.isPremium) return false;
    if (isFreehand) return promptText.value.trim().isNotEmpty;
    if (isByBucket) {
      return selectedBucketIds.isNotEmpty && selectedNodeCount > 0;
    }
    return selectedNodeIds.isNotEmpty;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    mode.value = QuizMode.fromWire(args?['mode']);
    // Seeded selections (e.g. from the Re-learn weak skills nudge).
    final seedNodes = (args?['node_ids'] as List?)?.cast<String>();
    final seedBuckets = (args?['bucket_ids'] as List?)?.cast<String>();
    if (seedNodes != null) selectedNodeIds.addAll(seedNodes);
    if (seedBuckets != null) selectedBucketIds.addAll(seedBuckets);
    promptController.addListener(() {
      promptText.value = promptController.text;
      inlineMessage.value = '';
    });
    _track('quiz_config_opened');
    _load();
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    try {
      await _tierService.refreshFromServer(_profileRepo, userId);

      final loadedBuckets = await _bucketRepo.fetchActiveBuckets(userId);
      final loadedNodeLists = await Future.wait(
        loadedBuckets.map((bucket) => _nodeRepo.fetchByBucket(bucket.id)),
      );

      final loadedNodes = loadedNodeLists.expand((list) => list).toList();
      buckets.assignAll(loadedBuckets);
      nodes.assignAll(loadedNodes);

      if (isByBucket && loadedBuckets.isNotEmpty) {
        selectedBucketIds.add(loadedBuckets.first.id);
      }
      if (isByNode && loadedNodes.isNotEmpty) {
        selectedNodeIds.add(loadedNodes.first.id);
      }

      if (!gate.isPremium) {
        inlineMessage.value = 'Quiz lives behind Premium.';
      } else if ((isByBucket || isByNode) && selectedNodeCount == 0) {
        inlineMessage.value = 'Add notes first.';
      }

      _syncStatus.setOffline(false);
      setSuccess();
    } on RepoException catch (e) {
      if (e.isOffline) _syncStatus.setOffline(true);
      setError(e.message);
    }
  }

  Future<void> reload() => _load();

  void onBackTap() {
    RecallHaptics.selection();
    Get.back();
  }

  void toggleBucket(String id) {
    RecallHaptics.selection();
    if (selectedBucketIds.contains(id)) {
      selectedBucketIds.remove(id);
    } else {
      selectedBucketIds.add(id);
    }
    _syncSelectionMessage();
  }

  void toggleNode(String id) {
    RecallHaptics.selection();
    if (selectedNodeIds.contains(id)) {
      selectedNodeIds.remove(id);
    } else {
      selectedNodeIds.add(id);
    }
    _syncSelectionMessage();
  }

  void _syncSelectionMessage() {
    if ((isByBucket || isByNode) && selectedNodeCount == 0) {
      inlineMessage.value = 'Add notes first.';
    } else {
      inlineMessage.value = '';
    }
  }

  void setUseMyNotes(bool value) => useMyNotes.value = value;

  void incrementCount() {
    if (questionCount.value >= 30) return;
    RecallHaptics.selection();
    questionCount.value++;
  }

  void decrementCount() {
    if (questionCount.value <= 5) return;
    RecallHaptics.selection();
    questionCount.value--;
  }

  void setQuestionType(QuizQuestionType value) {
    RecallHaptics.selection();
    questionType.value = value;
  }

  void setDifficulty(int value) {
    RecallHaptics.light();
    difficulty.value = value;
  }

  void setTimerEnabled(bool value) => timerEnabled.value = value;

  void applyGhostPrompt(String text) {
    final cleaned = text.replaceAll(RegExp(r'^try\s+'), '').replaceAll('"', '').trim();
    if (cleaned.isEmpty) return;
    promptController.text = cleaned;
    promptController.selection = TextSelection.collapsed(offset: cleaned.length);
    RecallHaptics.selection();
  }

  void _track(String event) {
    if (!_auth.analyticsOptIn) return;
    // Provider-agnostic analytics stub [D-OBS-2]; wired in a later sprint.
    debugPrint('analytics:$event');
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}
