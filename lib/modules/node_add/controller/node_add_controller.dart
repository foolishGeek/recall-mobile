import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/neo_chip.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';

class NodeAddController extends BaseController {
  NodeAddController(
    this._auth,
    this._nodeRepo,
    this._aiRepo,
    this._bucketRepo,
    this.tierService,
  );

  final AuthService _auth;
  final NodeRepository _nodeRepo;
  final AiRepository _aiRepo;
  final BucketRepository _bucketRepo;
  final TierService tierService;

  // ── Arguments ──
  bool get isEditMode => _existingNodeId != null;
  String? _existingNodeId;
  String? _initialBucketId;

  // ── Text controllers ──
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;
  late final TextEditingController urlCtrl;
  late final TextEditingController tagInputCtrl;

  // ── Reactive state ──
  final Rx<NodeType> selectedType = NodeType.text.obs;
  final RxInt priority = 3.obs;
  final RxInt difficulty = 3.obs;
  final RxInt comfort = 50.obs;
  final RxBool comfortReadOnly = false.obs;

  final RxList<Tag> allUserTags = <Tag>[].obs;
  final RxList<Tag> selectedTags = <Tag>[].obs;
  final RxList<Bucket> writableBuckets = <Bucket>[].obs;
  final Rxn<Bucket> selectedBucket = Rxn<Bucket>();

  final Rxn<LinkPreview> linkPreview = Rxn<LinkPreview>();
  final RxBool isPreviewLoading = false.obs;
  final RxnString previewError = RxnString();

  final Rxn<NodeType> detectedType = Rxn<NodeType>();
  final RxBool showDetectedChip = false.obs;

  final RxBool isSaving = false.obs;
  final RxBool bucketReadOnly = false.obs;
  final RxnString validationError = RxnString();

  final Rxn<Uint8List> pickedFileBytes = Rxn<Uint8List>();
  final RxnString pickedFileName = RxnString();
  final RxInt pickedFileSizeBytes = 0.obs;
  final RxBool isUploadingFile = false.obs;

  final RxBool _formValid = false.obs;

  Timer? _smartPasteTimer;
  Timer? _detectedChipTimer;
  Timer? _previewDebounce;

  Node? _existingNode;

  // ── Lifecycle ──

  @override
  void onInit() {
    super.onInit();
    titleCtrl = TextEditingController();
    bodyCtrl = TextEditingController();
    urlCtrl = TextEditingController();
    tagInputCtrl = TextEditingController();

    titleCtrl.addListener(_revalidate);
    urlCtrl.addListener(_revalidate);

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _existingNodeId = args['node_id'] as String?;
    _initialBucketId = args['bucket_id'] as String?;

    _loadInitialData();
  }

  @override
  void onClose() {
    titleCtrl.removeListener(_revalidate);
    urlCtrl.removeListener(_revalidate);
    titleCtrl.dispose();
    bodyCtrl.dispose();
    urlCtrl.dispose();
    tagInputCtrl.dispose();
    _smartPasteTimer?.cancel();
    _detectedChipTimer?.cancel();
    _previewDebounce?.cancel();
    super.onClose();
  }

  // ── Data loading ──

  Future<void> _loadInitialData() async {
    setLoading();
    try {
      final userId = _auth.currentUserId;
      if (userId == null) {
        setError('Not signed in.');
        return;
      }

      final results = await Future.wait([
        _bucketRepo.fetchActiveBuckets(userId),
        _nodeRepo.fetchTags(userId),
        if (_existingNodeId != null) _nodeRepo.fetchById(_existingNodeId!),
        if (_existingNodeId != null)
          _nodeRepo.fetchTagsForNode(_existingNodeId!),
        if (_existingNodeId != null) _nodeRepo.hasReviews(_existingNodeId!),
      ]);

      writableBuckets.assignAll(results[0] as List<Bucket>);
      allUserTags.assignAll(results[1] as List<Tag>);

      if (_existingNodeId != null) {
        _existingNode = results[2] as Node?;
        if (_existingNode != null) {
          _populateFromNode(_existingNode!);
          selectedTags.assignAll(results[3] as List<Tag>);
          comfortReadOnly.value = results[4] as bool;
          final nodeBucketWritable = writableBuckets
              .any((b) => b.id == _existingNode!.bucketId);
          if (!nodeBucketWritable) {
            bucketReadOnly.value = true;
            setError(
              'This note is in a read-only bucket. Resubscribe to edit.',
            );
            return;
          }
        }
      }

      if (selectedBucket.value == null && writableBuckets.isNotEmpty) {
        if (_initialBucketId != null) {
          selectedBucket.value = writableBuckets.firstWhereOrNull(
            (b) => b.id == _initialBucketId,
          );
        }
        selectedBucket.value ??= writableBuckets.first;
      }

      _revalidate();
      setSuccess();
    } on RepoException catch (e, st) {
      setError(e.message);
      _capture(e, st);
    }
  }

  void _populateFromNode(Node n) {
    titleCtrl.text = n.title;
    bodyCtrl.text = n.markdown ?? '';
    urlCtrl.text = n.url ?? '';
    selectedType.value = n.type;
    priority.value = n.priority;
    difficulty.value = n.difficulty;
    comfort.value = n.comfort;
    linkPreview.value = n.linkPreview;

    _initialBucketId ??= n.bucketId;
  }

  // ── Type switching ──

  void onTypeChanged(NodeType type) {
    RecallHaptics.selection();
    selectedType.value = type;
    previewError.value = null;
    linkPreview.value = null;
    _revalidate();
  }

  // ── Smart paste ──

  void onBodyOrUrlChanged(String text) {
    _smartPasteTimer?.cancel();
    _smartPasteTimer = Timer(const Duration(milliseconds: 400), () {
      _detectContentType(text);
    });
  }

  void _detectContentType(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return;

    final detected =
        _isYouTubeUrl(trimmed) ? NodeType.youtube : NodeType.link;

    if (detected != selectedType.value) {
      RecallHaptics.selection();
      detectedType.value = detected;
      selectedType.value = detected;
      urlCtrl.text = trimmed;
      showDetectedChip.value = true;

      _detectedChipTimer?.cancel();
      _detectedChipTimer = Timer(const Duration(milliseconds: 2400), () {
        showDetectedChip.value = false;
      });

      _fetchLinkPreview(trimmed);
    }
  }

  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com/watch') ||
        lower.contains('youtu.be/') ||
        lower.contains('youtube.com/embed/');
  }

  // ── Link preview ──

  void clearLinkPreview() {
    linkPreview.value = null;
    previewError.value = null;
  }

  void onUrlSubmitted(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _fetchLinkPreview(trimmed);
  }

  void _fetchLinkPreview(String url) {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 300), () async {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        previewError.value = "Doesn't look like a link we can read";
        linkPreview.value = null;
        return;
      }

      isPreviewLoading.value = true;
      previewError.value = null;
      try {
        final preview = await _aiRepo.linkPreview(url);
        linkPreview.value = preview;

        if (preview.videoId != null &&
            selectedType.value != NodeType.youtube) {
          selectedType.value = NodeType.youtube;
        }

        _trackEvent('link_previewed', {'url': url});
      } on RepoException catch (e, st) {
        previewError.value = e.message;
        _capture(e, st);
      } finally {
        isPreviewLoading.value = false;
      }
    });
  }

  // ── File picking (PDF / Image) ──

  void onFilePicked(Uint8List bytes, String name, String mimeType) {
    if (mimeType.contains('pdf') && bytes.lengthInBytes > 20 * 1024 * 1024) {
      validationError.value = 'PDF must be 20 MB or smaller';
      return;
    }
    pickedFileBytes.value = bytes;
    pickedFileName.value = name;
    pickedFileSizeBytes.value = bytes.lengthInBytes;
    validationError.value = null;
    _revalidate();
  }

  void clearPickedFile() {
    pickedFileBytes.value = null;
    pickedFileName.value = null;
    pickedFileSizeBytes.value = 0;
    _revalidate();
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

  NeoLevel comfortLevel(int val) {
    if (val <= 33) return NeoLevel.high;
    if (val <= 66) return NeoLevel.medium;
    return NeoLevel.low;
  }

  void onPriorityCycle() {
    RecallHaptics.light();
    priority.value = (priority.value % 5) + 1;
  }

  void onDifficultyCycle() {
    RecallHaptics.light();
    difficulty.value = (difficulty.value % 5) + 1;
  }

  void onComfortCycle() {
    if (comfortReadOnly.value) return;
    RecallHaptics.light();
    final cur = comfort.value;
    if (cur <= 33) {
      comfort.value = 50;
    } else if (cur <= 66) {
      comfort.value = 80;
    } else {
      comfort.value = 20;
    }
  }

  // ── Tags ──

  void onTagCommit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final existing = selectedTags.any(
      (t) => t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing) {
      tagInputCtrl.clear();
      return;
    }

    final matchedTag = allUserTags.firstWhereOrNull(
      (t) => t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (matchedTag != null) {
      selectedTags.add(matchedTag);
    } else {
      selectedTags.add(Tag(
        id: 'pending_${trimmed.hashCode}',
        userId: _auth.currentUserId ?? '',
        name: trimmed,
      ));
    }
    tagInputCtrl.clear();
  }

  void onTagRemoved(Tag tag) {
    selectedTags.removeWhere((t) => t.id == tag.id);
  }

  // ── Bucket selection ──

  void onBucketSelected(Bucket bucket) {
    selectedBucket.value = bucket;
    _revalidate();
    Get.back();
  }

  Future<void> onCreateBucket(String name) async {
    try {
      final userId = _auth.currentUserId;
      if (userId == null) return;

      final bucket = await _bucketRepo.create(
        Bucket(id: '', userId: userId, name: name),
      );
      writableBuckets.add(bucket);
      selectedBucket.value = bucket;
      _revalidate();
      RecallHaptics.selection();
    } on RepoException catch (e, st) {
      validationError.value = e.message;
      _capture(e, st);
    }
  }

  // ── Validation ──

  String? _validate() {
    if (titleCtrl.text.trim().isEmpty) return 'Title is required';

    final type = selectedType.value;
    if (type == NodeType.link || type == NodeType.youtube) {
      if (urlCtrl.text.trim().isEmpty) return 'URL is required';
    }
    if (type == NodeType.pdf || type == NodeType.image) {
      if (!isEditMode && pickedFileBytes.value == null) {
        return 'Please select a file';
      }
    }
    if (type == NodeType.pdf &&
        pickedFileBytes.value != null &&
        pickedFileSizeBytes.value > 20 * 1024 * 1024) {
      return 'PDF must be 20 MB or smaller';
    }
    if (selectedBucket.value == null) return 'Select a bucket';
    return null;
  }

  void _revalidate() {
    _formValid.value = _validate() == null;
  }

  bool get canSave =>
      _formValid.value && !isSaving.value && !bucketReadOnly.value;

  // ── Save ──

  Future<void> onSave() async {
    final error = _validate();
    if (error != null) {
      validationError.value = error;
      return;
    }

    validationError.value = null;
    isSaving.value = true;
    RecallHaptics.medium();

    try {
      final userId = _auth.currentUserId!;
      final bucket = selectedBucket.value!;
      final type = selectedType.value;

      // Build the content hash for text-based types.
      String? contentHash;
      String? extractedText;
      final hashableText = _buildHashableText(type);
      if (hashableText.isNotEmpty) {
        contentHash = NodeRepository.computeContentHash(hashableText);
        extractedText = hashableText;
      }

      if (isEditMode) {
        await _updateExistingNode(type, contentHash, extractedText);
      } else {
        await _createNewNode(userId, bucket, type, contentHash, extractedText);
      }

      // Sync tags.
      final nodeId = _existingNodeId!;
      final tagIds = await _resolveTagIds(userId);
      await _nodeRepo.syncNodeTags(nodeId, tagIds);

      final eventName = isEditMode ? 'node_edited' : 'node_created';
      _trackEvent(eventName, {
        'node_id': nodeId,
        'type': type.wire,
      });

      Get.back(result: true);
    } on RepoException catch (e, st) {
      validationError.value = e.message;
      _capture(e, st);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _createNewNode(
    String userId,
    Bucket bucket,
    NodeType type,
    String? contentHash,
    String? extractedText,
  ) async {
    final nodeId = const Uuid().v4();

    final node = Node(
      id: nodeId,
      bucketId: bucket.id,
      type: type,
      title: titleCtrl.text.trim(),
      markdown: type == NodeType.text ? bodyCtrl.text : null,
      url: _urlForType(type),
      linkPreview: linkPreview.value,
      priority: priority.value,
      difficulty: difficulty.value,
      comfort: comfort.value,
      contentHash: contentHash,
      extractedText: extractedText,
    );

    final created = await _nodeRepo.create(node);
    _existingNodeId = created.id;

    await _handleFileUpload(created.id, userId, type);
  }

  Future<void> _updateExistingNode(
    NodeType type,
    String? contentHash,
    String? extractedText,
  ) async {
    final changes = <String, dynamic>{
      'type': type.wire,
      'title': titleCtrl.text.trim(),
      'markdown': type == NodeType.text ? bodyCtrl.text : null,
      'url': _urlForType(type),
      'link_preview_json': linkPreview.value?.toJson(),
      'priority': priority.value,
      'difficulty': difficulty.value,
      'comfort': comfort.value,
      if (contentHash != null) 'content_hash': contentHash,
      if (extractedText != null) 'extracted_text': extractedText,
    };

    if (selectedBucket.value != null) {
      changes['bucket_id'] = selectedBucket.value!.id;
    }

    await _nodeRepo.update(_existingNodeId!, changes);

    if (pickedFileBytes.value != null) {
      await _handleFileUpload(
          _existingNodeId!, _auth.currentUserId!, type);
    }
  }

  String? _urlForType(NodeType type) {
    if (type == NodeType.link || type == NodeType.youtube) {
      return urlCtrl.text.trim();
    }
    return null;
  }

  String _buildHashableText(NodeType type) {
    switch (type) {
      case NodeType.text:
        return bodyCtrl.text;
      case NodeType.link:
      case NodeType.youtube:
        final lp = linkPreview.value;
        return [lp?.title, lp?.description, urlCtrl.text.trim()]
            .where((s) => s != null && s.isNotEmpty)
            .join('\n');
      case NodeType.pdf:
      case NodeType.image:
        return '';
    }
  }

  Future<void> _handleFileUpload(
    String nodeId,
    String userId,
    NodeType type,
  ) async {
    final bytes = pickedFileBytes.value;
    if (bytes == null) return;

    isUploadingFile.value = true;
    try {
      final isPdf = type == NodeType.pdf;
      final bucket = isPdf ? 'node-pdfs' : 'node-images';
      final ext = isPdf ? 'pdf' : _imageExt(pickedFileName.value ?? 'img.png');
      final path = '$userId/nodes/$nodeId/file.$ext';
      final mime = isPdf ? 'application/pdf' : 'image/$ext';

      await _nodeRepo.uploadToStorage(
        storageBucket: bucket,
        path: path,
        bytes: bytes,
        contentType: mime,
      );

      await _nodeRepo.createNodeAsset(
        nodeId: nodeId,
        storagePath: path,
        mimeType: mime,
        fileSizeBytes: bytes.lengthInBytes,
      );

      if (isPdf) {
        unawaited(_aiRepo.extractPdfText(path));
      }
    } finally {
      isUploadingFile.value = false;
    }
  }

  String _imageExt(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return 'jpg';
  }

  Future<List<String>> _resolveTagIds(String userId) async {
    final ids = <String>[];
    for (final tag in selectedTags) {
      if (tag.id.startsWith('pending_')) {
        final created = await _nodeRepo.createTag(userId, tag.name);
        ids.add(created.id);
      } else {
        ids.add(tag.id);
      }
    }
    return ids;
  }

  // ── Soft delete ──

  Future<void> onDeleteNode() async {
    if (!isEditMode) return;
    isSaving.value = true;
    try {
      await _nodeRepo.softDelete(_existingNodeId!);
      Get.back(result: true);
    } on RepoException catch (e, st) {
      validationError.value = e.message;
      _capture(e, st);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Analytics / Sentry ──

  void _trackEvent(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'analytics',
      message: name,
      data: params,
    ));
  }

  void _capture(Object error, StackTrace st) {
    Sentry.captureException(error, stackTrace: st,
        withScope: (s) => s.setTag('feature', 'node_add'));
  }
}
