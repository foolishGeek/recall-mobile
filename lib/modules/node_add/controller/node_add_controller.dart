import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/coach_keys.dart';
import '../../../core/utils/note_links.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/neo_chip.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';
import 'picked_file.dart';

class NodeAddController extends BaseController {
  NodeAddController(
    this._auth,
    this._nodeRepo,
    this._aiRepo,
    this._bucketRepo,
    this.tierService,
    this._local,
  );

  final AuthService _auth;
  final NodeRepository _nodeRepo;
  final AiRepository _aiRepo;
  final BucketRepository _bucketRepo;
  final TierService tierService;
  final LocalStore _local;

  // ── Arguments ──
  bool get isEditMode => _existingNodeId != null;
  String? _existingNodeId;
  String? _initialBucketId;

  // ── Text controllers ──
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;
  late final TextEditingController linkUrlCtrl;
  late final TextEditingController youtubeUrlCtrl;
  late final TextEditingController tagInputCtrl;

  // ── Reactive state ──
  final RxInt priority = 3.obs;
  final RxInt difficulty = 3.obs;
  final RxInt comfort = 50.obs;
  final RxBool comfortReadOnly = false.obs;

  final RxList<Tag> allUserTags = <Tag>[].obs;
  final RxList<Tag> selectedTags = <Tag>[].obs;
  final RxList<Bucket> writableBuckets = <Bucket>[].obs;
  final Rxn<Bucket> selectedBucket = Rxn<Bucket>();

  /// Whether this note joins spaced revision. Defaults to the selected bucket's
  /// setting for new notes; loaded from the note when editing. User-overridable.
  final RxBool srEnabled = true.obs;
  bool _srManuallySet = false;

  /// One-time inline explainer for the spaced-revision toggle (first note only).
  final RxBool showSrCoachTip = false.obs;

  Future<void> dismissSrCoachTip() async {
    if (!showSrCoachTip.value) return;
    showSrCoachTip.value = false;
    await _local.markCoachSeen(CoachKeys.noteSrToggle);
  }

  // ── Reference links (added via CTAs below attachments) ──
  final RxBool showLinkField = false.obs;
  final RxBool showYoutubeField = false.obs;
  final RxnString linkError = RxnString();
  final RxnString youtubeError = RxnString();

  final RxBool isSaving = false.obs;
  final RxBool bucketReadOnly = false.obs;
  final RxnString validationError = RxnString();

  // ── Unified attachments (multiple PDFs + images, any note type) ──
  final RxList<PickedFile> pickedFiles = <PickedFile>[].obs;
  final RxList<NodeAsset> existingAssets = <NodeAsset>[].obs;
  final RxMap<String, String> existingSignedUrls = <String, String>{}.obs;
  final List<NodeAsset> _removedAssets = [];
  final RxBool isUploadingFile = false.obs;

  int get attachmentCount => existingAssets.length + pickedFiles.length;
  bool get hasAttachments => attachmentCount > 0;

  final RxBool _formValid = false.obs;

  Node? _existingNode;

  // ── Lifecycle ──

  @override
  void onInit() {
    super.onInit();
    titleCtrl = TextEditingController();
    bodyCtrl = TextEditingController();
    linkUrlCtrl = TextEditingController();
    youtubeUrlCtrl = TextEditingController();
    tagInputCtrl = TextEditingController();

    titleCtrl.addListener(_revalidate);
    linkUrlCtrl.addListener(_onLinkChanged);
    youtubeUrlCtrl.addListener(_onYoutubeChanged);

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _existingNodeId = args['node_id'] as String?;
    _initialBucketId = args['bucket_id'] as String?;

    _loadInitialData();
  }

  @override
  void onClose() {
    titleCtrl.removeListener(_revalidate);
    linkUrlCtrl.removeListener(_onLinkChanged);
    youtubeUrlCtrl.removeListener(_onYoutubeChanged);
    titleCtrl.dispose();
    bodyCtrl.dispose();
    linkUrlCtrl.dispose();
    youtubeUrlCtrl.dispose();
    tagInputCtrl.dispose();
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
        if (_existingNodeId != null) _nodeRepo.fetchAssets(_existingNodeId!),
      ]);

      writableBuckets.assignAll(results[0] as List<Bucket>);
      allUserTags.assignAll(results[1] as List<Tag>);

      if (_existingNodeId != null) {
        _existingNode = results[2] as Node?;
        if (_existingNode != null) {
          _populateFromNode(_existingNode!);
          selectedTags.assignAll(results[3] as List<Tag>);
          comfortReadOnly.value = results[4] as bool;
          existingAssets.assignAll(results[5] as List<NodeAsset>);
          _signExistingAssets();
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

      // Only pre-select when the user entered from a specific bucket (individual
      // bucket screen, or editing an existing note). From the Buckets-tab CTA,
      // Today, onboarding or empty states no bucket_id is passed, so we leave the
      // picker empty and make the user choose — this is what stops notes silently
      // landing in the wrong (first) bucket.
      if (selectedBucket.value == null &&
          _initialBucketId != null &&
          writableBuckets.isNotEmpty) {
        selectedBucket.value = writableBuckets.firstWhereOrNull(
          (b) => b.id == _initialBucketId,
        );
      }

      // New note default: inherit the chosen bucket's spaced-revision setting.
      if (!isEditMode && selectedBucket.value != null) {
        srEnabled.value = selectedBucket.value!.srEnabled;
      }

      _revalidate();
      setSuccess();

      // Explain spaced revision once, only on the create flow.
      if (!isEditMode && !await _local.coachSeen(CoachKeys.noteSrToggle)) {
        showSrCoachTip.value = true;
      }
    } on RepoException catch (e, st) {
      setError(e.message);
      _capture(e, st);
    }
  }

  void _populateFromNode(Node n) {
    titleCtrl.text = n.title;
    priority.value = n.priority;
    difficulty.value = n.difficulty;
    comfort.value = n.comfort;
    srEnabled.value = n.srEnabled;
    _srManuallySet = true; // preserve the note's own setting on edit

    // Reference links/videos are stored as standalone URL lines in markdown.
    // Split them back into the dedicated fields; keep prose as the body.
    bodyCtrl.text = stripStandaloneUrls(n.markdown);

    final urls = <String>[
      // Legacy link/youtube nodes stored their URL in `url`.
      if (n.url != null && n.url!.trim().isNotEmpty) n.url!.trim(),
      ...standaloneUrls(n.markdown),
    ];
    for (final url in urls) {
      if (isYoutubeUrl(url)) {
        if (youtubeUrlCtrl.text.isEmpty) {
          youtubeUrlCtrl.text = url;
          showYoutubeField.value = true;
        }
      } else {
        if (linkUrlCtrl.text.isEmpty) {
          linkUrlCtrl.text = url;
          showLinkField.value = true;
        }
      }
    }

    _initialBucketId ??= n.bucketId;
  }

  // ── Reference links (link + YouTube CTAs) ──

  void toggleLinkField() {
    RecallHaptics.selection();
    showLinkField.value = !showLinkField.value;
    if (!showLinkField.value) {
      linkUrlCtrl.clear();
      linkError.value = null;
    }
    _revalidate();
  }

  void toggleYoutubeField() {
    RecallHaptics.selection();
    showYoutubeField.value = !showYoutubeField.value;
    if (!showYoutubeField.value) {
      youtubeUrlCtrl.clear();
      youtubeError.value = null;
    }
    _revalidate();
  }

  void _onLinkChanged() {
    final t = linkUrlCtrl.text.trim();
    linkError.value =
        (t.isEmpty || isValidHttpUrl(t)) ? null : 'Enter a valid https link';
    _revalidate();
  }

  void _onYoutubeChanged() {
    final t = youtubeUrlCtrl.text.trim();
    youtubeError.value =
        (t.isEmpty || isYoutubeUrl(t)) ? null : 'Enter a valid YouTube link';
    _revalidate();
  }

  // ── Attachments (multi PDF / image) ──

  Future<void> _signExistingAssets() async {
    for (final asset in existingAssets) {
      if (asset.storagePath.isEmpty) continue;
      try {
        final url =
            await _nodeRepo.signAssetUrl(asset.storagePath, asset.mimeType);
        existingSignedUrls[asset.id] = url;
      } catch (_) {}
    }
  }

  /// Appends newly picked files. Enforces the 20 MB per-PDF cap; oversized PDFs
  /// are skipped with a quiet validation message.
  void onFilesPicked(List<PickedFile> files) {
    var rejected = false;
    for (final f in files) {
      if (f.isPdf && f.sizeBytes > 20 * 1024 * 1024) {
        rejected = true;
        continue;
      }
      pickedFiles.add(f);
    }
    validationError.value = rejected ? 'PDF must be 20 MB or smaller' : null;
    RecallHaptics.selection();
    _revalidate();
  }

  void removePickedFile(PickedFile file) {
    pickedFiles.remove(file);
    _revalidate();
  }

  /// Marks an already-saved asset for deletion; it's removed from view now and
  /// its row + Storage object are deleted on save.
  void removeExistingAsset(NodeAsset asset) {
    existingAssets.remove(asset);
    existingSignedUrls.remove(asset.id);
    _removedAssets.add(asset);
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
    // New note that hasn't been manually toggled follows the bucket's default.
    if (!isEditMode && !_srManuallySet) {
      srEnabled.value = bucket.srEnabled;
    }
    _revalidate();
    Get.back();
  }

  /// User intent: include/exclude this note from spaced revision.
  void toggleSrEnabled(bool value) {
    _srManuallySet = true;
    srEnabled.value = value;
    RecallHaptics.selection();
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

    final link = linkUrlCtrl.text.trim();
    if (showLinkField.value && link.isNotEmpty && !isValidHttpUrl(link)) {
      return 'Enter a valid https link';
    }
    final yt = youtubeUrlCtrl.text.trim();
    if (showYoutubeField.value && yt.isNotEmpty && !isYoutubeUrl(yt)) {
      return 'Enter a valid YouTube link';
    }
    for (final f in pickedFiles) {
      if (f.isPdf && f.sizeBytes > 20 * 1024 * 1024) {
        return 'PDF must be 20 MB or smaller';
      }
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
      const type = NodeType.text;

      final markdown = _composeMarkdown();

      String? contentHash;
      String? extractedText;
      if (markdown.isNotEmpty) {
        contentHash = NodeRepository.computeContentHash(markdown);
        extractedText = markdown;
      }

      if (isEditMode) {
        await _updateExistingNode(markdown, contentHash, extractedText);
      } else {
        await _createNewNode(
            userId, bucket, markdown, contentHash, extractedText);
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
    String markdown,
    String? contentHash,
    String? extractedText,
  ) async {
    final nodeId = const Uuid().v4();

    final node = Node(
      id: nodeId,
      bucketId: bucket.id,
      type: NodeType.text,
      title: titleCtrl.text.trim(),
      markdown: markdown.isEmpty ? null : markdown,
      priority: priority.value,
      difficulty: difficulty.value,
      comfort: comfort.value,
      srEnabled: srEnabled.value,
      contentHash: contentHash,
      extractedText: extractedText,
    );

    final created = await _nodeRepo.create(node);
    _existingNodeId = created.id;

    await _syncAttachments(created.id, userId);
  }

  Future<void> _updateExistingNode(
    String markdown,
    String? contentHash,
    String? extractedText,
  ) async {
    final changes = <String, dynamic>{
      'type': NodeType.text.wire,
      'title': titleCtrl.text.trim(),
      'markdown': markdown.isEmpty ? null : markdown,
      // Reference links now live inside markdown; clear legacy single-link cols.
      'url': null,
      'link_preview_json': null,
      'priority': priority.value,
      'difficulty': difficulty.value,
      'comfort': comfort.value,
      'sr_enabled': srEnabled.value,
      if (contentHash != null) 'content_hash': contentHash,
      if (extractedText != null) 'extracted_text': extractedText,
    };

    if (selectedBucket.value != null) {
      changes['bucket_id'] = selectedBucket.value!.id;
    }

    await _nodeRepo.update(_existingNodeId!, changes);

    await _syncAttachments(_existingNodeId!, _auth.currentUserId!);
  }

  /// Body prose followed by any reference links/videos as standalone URL lines,
  /// so the detail view can render them as rich cards.
  String _composeMarkdown() {
    final parts = <String>[];
    final body = bodyCtrl.text.trim();
    if (body.isNotEmpty) parts.add(body);

    final link = linkUrlCtrl.text.trim();
    if (showLinkField.value && isValidHttpUrl(link)) parts.add(link);

    final yt = youtubeUrlCtrl.text.trim();
    if (showYoutubeField.value && isYoutubeUrl(yt)) parts.add(yt);

    return parts.join('\n\n');
  }

  /// Uploads any newly picked files and deletes any removed existing assets
  /// (row + Storage). Supports multiple + mixed PDF/image per note.
  Future<void> _syncAttachments(String nodeId, String userId) async {
    for (final asset in _removedAssets) {
      await _nodeRepo.deleteNodeAsset(
        asset.id,
        storagePath: asset.storagePath,
        mimeType: asset.mimeType,
      );
    }
    _removedAssets.clear();

    if (pickedFiles.isEmpty) return;

    isUploadingFile.value = true;
    try {
      final base = existingAssets.length;
      for (var i = 0; i < pickedFiles.length; i++) {
        final f = pickedFiles[i];
        final storageBucket = f.isPdf ? 'node-pdfs' : 'node-images';
        final ext = f.isPdf ? 'pdf' : _imageExt(f.name);
        final path = '$userId/nodes/$nodeId/${const Uuid().v4()}.$ext';
        final mime = f.isPdf ? 'application/pdf' : 'image/$ext';

        await _nodeRepo.uploadToStorage(
          storageBucket: storageBucket,
          path: path,
          bytes: f.bytes,
          contentType: mime,
        );

        await _nodeRepo.createNodeAsset(
          nodeId: nodeId,
          storagePath: path,
          mimeType: mime,
          fileSizeBytes: f.sizeBytes,
          sortOrder: base + i,
        );

        if (f.isPdf) {
          unawaited(_aiRepo.extractPdfText(path));
        }
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
