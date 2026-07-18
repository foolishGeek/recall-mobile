import 'package:get/get.dart' hide Node;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/note_links.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/neo_chip.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/node_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';
import '../view/widgets/node_ai_diff_view.dart';
import '../view/widgets/node_ask_ai_update_sheet.dart';

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
  final RxInt evalRating = 0.obs;

  // Rewrite apply/revert state. Holds the pre-rewrite body so the user can
  // revert Aura's applied suggestion from a quiet chip in the body.
  final RxnString _preRewriteMarkdown = RxnString();
  final RxBool didApplyRewrite = false.obs;
  bool get canRevertRewrite =>
      didApplyRewrite.value && _preRewriteMarkdown.value != null;

  // Local dismissals for Aura closer-match nudges (this screen session only).
  final RxSet<String> dismissedLinkSuggestions = <String>{}.obs;

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

  /// True when Aura returned a body rewrite that differs from the current note,
  /// so the panel offers "Review rewrite" instead of a plain metadata apply.
  bool get hasSuggestion {
    final s = evaluation.value?.suggestedMarkdown;
    if (s == null || s.trim().isEmpty) return false;
    return s.trim() != (node.value?.markdown ?? '').trim();
  }

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
      setError('No note ID provided.');
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
        setError('Note not found.');
        return;
      }
      node.value = loadedNode;
      assets.assignAll(results[1] as List<NodeAsset>);
      tags.assignAll(results[2] as List<Tag>);
      heatPct.value = results[3] as double;
      hasReviews.value = results[4] as bool;
      final loadedEval = results[5] as AiEvaluation?;
      evaluation.value = loadedEval == null
          ? null
          : _withPreservedUrls(loadedEval, loadedNode.markdown);
      dismissedLinkSuggestions.clear();

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

    final seen = <String>{};
    final urls = <String>[];

    // 1) Link / YouTube nodes keep their URL on `n.url` (not in markdown). If
    //    the stored structured preview is missing/empty, seed a card from that
    //    URL so a link node never renders as a bare link.
    final structuredUrl = n.linkPreview?.canonicalUrl;
    if ((n.type == NodeType.link || n.type == NodeType.youtube) &&
        n.url != null &&
        n.url!.trim().isNotEmpty &&
        (structuredUrl == null || structuredUrl.isEmpty)) {
      final u = n.url!.trim();
      if (seen.add(u)) urls.add(u);
    }

    // 2) Any URLs written inside the markdown body (text notes).
    final md = n.markdown;
    if (md != null && md.trim().isNotEmpty) {
      for (final match in _urlRegex.allMatches(md)) {
        var url = match.group(0)!;
        // Strip trailing punctuation that commonly hugs a URL in prose.
        url = url.replaceAll(RegExp(r'[.,;:!?]+$'), '');
        if (url == structuredUrl) continue;
        if (seen.add(url)) urls.add(url);
        if (urls.length >= 6) break; // keep the screen + network bounded
      }
    }

    if (urls.isEmpty) return;

    // Show cards immediately (domain + favicon, YouTube id resolved client-side)
    // so a slow/unreachable `link-preview` edge function never leaves the note
    // as raw text. Each preview then enriches in place as it resolves.
    contentLinks.assignAll([for (final u in urls) _seedPreview(u)]);

    await Future.wait([
      for (var i = 0; i < urls.length; i++) _enrichLink(urls[i], i),
    ]);
  }

  /// Immediate placeholder preview from just the URL. Detects YouTube so the
  /// WATCH card shows right away without waiting on enrichment.
  LinkPreview _seedPreview(String url) {
    final videoId = _youtubeId(url);
    return LinkPreview(canonicalUrl: url, videoId: videoId);
  }

  /// Extracts a YouTube video id from common URL shapes; null if not YouTube.
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

  Future<void> _enrichLink(String url, int index) async {
    try {
      final preview = await _aiRepo
          .linkPreview(url)
          .timeout(const Duration(seconds: 6));
      var enriched =
          preview.canonicalUrl == null || preview.canonicalUrl!.isEmpty
              ? preview.copyWith(canonicalUrl: url)
              : preview;
      // Preserve the client-detected YouTube id if enrichment omitted it.
      if (enriched.videoId == null || enriched.videoId!.isEmpty) {
        final vid = _youtubeId(url);
        if (vid != null) enriched = enriched.copyWith(videoId: vid);
      }
      if (index < contentLinks.length) {
        contentLinks[index] = enriched;
      }
    } catch (_) {
      // Keep the bare-URL fallback already in place (offline, blocked, timeout).
    }
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
  ) =>
      _updateNodeFields({field: value}, optimistic);

  Future<void> _updateNodeFields(
    Map<String, dynamic> changes,
    Node optimistic,
  ) async {
    final prev = node.value;
    node.value = optimistic;
    try {
      final updated = await _nodeRepo.update(nodeId, changes);
      node.value = updated;
    } on RepoException catch (e, st) {
      node.value = prev;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    }
  }

  // ── AI Evaluation ──

  Future<void> _triggerEvaluate({bool forceRefresh = false}) async {
    if (!showAiPanel || overviewLocked) return;
    isEvalLoading.value = true;
    evalError.value = null;
    _trackEvent('ai_overview_viewed', {'node_id': nodeId});
    try {
      final result =
          await _aiRepo.evaluate(nodeId, forceRefresh: forceRefresh);
      final draft = AiEvaluation(
        id: '',
        nodeId: nodeId,
        qualityScore: result.qualityScore,
        suggestedComfort: result.suggestedComfort,
        suggestedDifficulty: result.suggestedDifficulty,
        feedback: result.feedback,
        suggestedMarkdown: result.suggestedMarkdown,
        linkSuggestions: result.linkSuggestions,
        model: result.model,
        interactionId: result.interactionId,
      );
      evaluation.value = _withPreservedUrls(draft, node.value?.markdown);
      dismissedLinkSuggestions.clear();
      evalRating.value = 0;
    } on RepoException catch (e, st) {
      evalError.value = e.message;
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    } finally {
      isEvalLoading.value = false;
    }
  }

  Future<void> onRegenerateTap() async {
    await _triggerEvaluate(forceRefresh: true);
  }

  /// Panel primary action. When Aura proposed a body rewrite, open the diff
  /// review sheet; otherwise apply the suggested comfort/difficulty metadata.
  Future<void> onApplySuggestion() async {
    final eval = evaluation.value;
    if (eval == null) return;
    if (hasSuggestion) {
      await _reviewRewrite();
      return;
    }
    RecallHaptics.light();
    _applyMetadata(eval);
  }

  void _applyMetadata(AiEvaluation eval) {
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
      _updateNodeFields(changes, updated);
    }
  }

  /// Shows the git-style diff and, on accept, swaps the note body to Aura's
  /// rewrite while remembering the previous body for one-tap revert.
  Future<void> _reviewRewrite() async {
    final ctx = Get.context;
    final n = node.value;
    final eval = evaluation.value;
    final rawAfter = eval?.suggestedMarkdown;
    if (ctx == null || n == null || rawAfter == null) return;

    final before = n.markdown ?? '';
    // Never let Apply wipe standalone URL lines (LINKED / WATCH cards).
    final after = mergeStandaloneUrls(before, rawAfter);
    final apply = await NodeAiDiffView.show(
      ctx,
      before: before,
      after: after,
      feedback: eval?.feedback,
    );
    if (apply != true) return;

    // Never write an empty prose body over real note text.
    final beforeProse = stripStandaloneUrls(before);
    if (beforeProse.isNotEmpty && stripStandaloneUrls(after).isEmpty) {
      Get.snackbar(
        'Rewrite skipped',
        'Aura\'s rewrite removed your note text. Nothing was changed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    RecallHaptics.medium();
    _preRewriteMarkdown.value = before;
    // Keep the searchable corpus + embeddings in sync with the new body, else
    // Summarise / Ask AI keep reading the stale `extracted_text`. Bumping
    // content_hash also re-fires the embed trigger to refresh the vectors.
    final hash = NodeRepository.computeContentHash(after);
    await _updateNodeFields(
      {'markdown': after, 'extracted_text': after, 'content_hash': hash},
      n.copyWith(markdown: after, extractedText: after, contentHash: hash),
    );
    didApplyRewrite.value = true;
    final current = node.value;
    if (current != null) _loadContentLinks(current);
    _trackEvent('ai_rewrite_applied', {'node_id': nodeId});
  }

  /// Closer-match suggestion for a LINKED/WATCH card URL, if any and not dismissed.
  LinkSuggestion? linkSuggestionFor(String? url) {
    if (url == null || url.isEmpty) return null;
    if (dismissedLinkSuggestions.contains(_urlKey(url))) return null;
    final list = evaluation.value?.linkSuggestions ?? const <LinkSuggestion>[];
    for (final s in list) {
      if (_urlsMatch(s.currentUrl, url)) return s;
    }
    return null;
  }

  /// How many closer-match nudges are still visible (cap UX at 2 from server).
  int get visibleLinkSuggestionCount {
    final list = evaluation.value?.linkSuggestions ?? const <LinkSuggestion>[];
    var n = 0;
    for (final s in list) {
      if (!dismissedLinkSuggestions.contains(_urlKey(s.currentUrl))) n++;
    }
    return n;
  }

  void dismissLinkSuggestion(String currentUrl) {
    dismissedLinkSuggestions.add(_urlKey(currentUrl));
    RecallHaptics.selection();
  }

  /// Swap one standalone URL line for Aura's closer match; refresh that card.
  Future<void> acceptLinkSuggestion(LinkSuggestion suggestion) async {
    final n = node.value;
    if (n == null) return;
    final next = replaceStandaloneUrl(
      n.markdown,
      suggestion.currentUrl,
      suggestion.suggestedUrl,
    );
    if (next == (n.markdown ?? '')) return;

    RecallHaptics.light();
    dismissedLinkSuggestions.add(_urlKey(suggestion.currentUrl));
    final hash = NodeRepository.computeContentHash(next);
    await _updateNodeFields(
      {'markdown': next, 'extracted_text': next, 'content_hash': hash},
      n.copyWith(markdown: next, extractedText: next, contentHash: hash),
    );
    final current = node.value;
    if (current != null) _loadContentLinks(current);
    _trackEvent('ai_link_suggestion_accepted', {
      'node_id': nodeId,
      'from': suggestion.currentUrl,
      'to': suggestion.suggestedUrl,
    });
  }

  /// Ensure cached/fresh suggested_markdown still carries the note's URL lines.
  AiEvaluation _withPreservedUrls(AiEvaluation eval, String? markdown) {
    final raw = eval.suggestedMarkdown;
    if (raw == null) return eval;
    final merged = mergeStandaloneUrls(markdown, raw);
    if (merged == raw) return eval;
    return eval.copyWith(suggestedMarkdown: merged);
  }

  static String _urlKey(String u) =>
      u.trim().replaceAll(RegExp(r'/+$'), '').toLowerCase();

  /// Match card URL to suggestion even if www / trailing slash / case differ.
  static bool _urlsMatch(String a, String b) {
    if (_urlKey(a) == _urlKey(b)) return true;
    final ua = Uri.tryParse(a.trim());
    final ub = Uri.tryParse(b.trim());
    if (ua == null || ub == null) return false;
    final hostA = ua.host.replaceFirst(RegExp(r'^www\.'), '').toLowerCase();
    final hostB = ub.host.replaceFirst(RegExp(r'^www\.'), '').toLowerCase();
    final pathA = ua.path.replaceAll(RegExp(r'/+$'), '').toLowerCase();
    final pathB = ub.path.replaceAll(RegExp(r'/+$'), '').toLowerCase();
    return hostA == hostB && pathA == pathB;
  }

  /// Restore the note body to what it was before applying Aura's rewrite.
  Future<void> revertRewrite() async {
    final prev = _preRewriteMarkdown.value;
    final n = node.value;
    if (prev == null || n == null) return;
    RecallHaptics.light();
    final hash = NodeRepository.computeContentHash(prev);
    await _updateNodeFields(
      {'markdown': prev, 'extracted_text': prev, 'content_hash': hash},
      n.copyWith(markdown: prev, extractedText: prev, contentHash: hash),
    );
    didApplyRewrite.value = false;
    _preRewriteMarkdown.value = null;
    final current = node.value;
    if (current != null) _loadContentLinks(current);
    _trackEvent('ai_rewrite_reverted', {'node_id': nodeId});
  }

  /// Thumbs feedback on the evaluation; tapping the active thumb clears it.
  Future<void> rateEval(int rating) async {
    final id = evaluation.value?.interactionId;
    if (id == null) return;
    final next = evalRating.value == rating ? 0 : rating;
    evalRating.value = next;
    RecallHaptics.selection();
    // Queue-aware + best-effort; never block the UI on a failed/queued rating.
    await _aiRepo.submitRating(id, next);
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

  /// Opens the keep/leave sheet, then appends the chosen excerpt to the note
  /// body (and keeps extracted_text + embeddings in sync).
  Future<void> onUpdateNoteFromAskAi(String answer) async {
    final ctx = Get.context;
    final n = node.value;
    if (ctx == null || n == null) return;

    final excerpt = await NodeAskAiUpdateSheet.show(ctx, answer: answer);
    if (excerpt == null || excerpt.trim().isEmpty) return;

    final existing = n.markdown?.trim() ?? '';
    final after =
        existing.isEmpty ? excerpt.trim() : '$existing\n\n${excerpt.trim()}';
    final hash = NodeRepository.computeContentHash(after);

    RecallHaptics.medium();
    await _updateNodeFields(
      {'markdown': after, 'extracted_text': after, 'content_hash': hash},
      n.copyWith(markdown: after, extractedText: after, contentHash: hash),
    );

    clearRagResult();
    final current = node.value;
    if (current != null) _loadContentLinks(current);
    _trackEvent('ask_ai_applied_to_note', {'node_id': nodeId});
  }

  // ── Navigation ──

  void onEditTap() {
    RecallHaptics.selection();
    Get.toNamed(Routes.nodeAdd, arguments: {
      'node_id': nodeId,
      'bucket_id': node.value?.bucketId,
    });
  }

  /// Soft-deletes the note and returns to the bucket, which reloads its list.
  Future<void> onDeleteNote() async {
    if (nodeId.isEmpty) return;
    RecallHaptics.heavy();
    try {
      await _nodeRepo.softDelete(nodeId);
      Get.back();
    } on RepoException catch (e, st) {
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('feature', 'node_detail'));
    }
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
