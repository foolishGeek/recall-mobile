// Recall · AiChatController. Ephemeral RAG chat over the user's active-bucket
// notes. All decisioning (retrieval scope, model routing, quota/credit/cooldown)
// is backend-authoritative via `ai-forge` `rag_chat`; this controller only holds
// the in-memory thread, simulates the answer typing, and maps the canonical
// error codes to the right UI (locked composer / cooldown interstitial / retry).

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/brand/aura_prefs.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/bucket_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/tier_service.dart';
import '../view/widgets/ai_cooldown_sheet.dart';
import '../view/widgets/aura_rating_sheet.dart';
import 'ai_chat_turn.dart';

/// Answer lifecycle: idle (no in-flight answer), searching (waiting on the EF),
/// streaming (simulated typing of the returned answer).
enum AnswerPhase { idle, searching, streaming }

/// ~28 characters per second simulated typing [S20 §9].
const Duration _kTypeStep = Duration(milliseconds: 36);

class AiChatController extends BaseController {
  AiChatController(
    this._auth,
    this._aiRepo,
    this._bucketRepo,
    this._profileRepo,
    this._tierService,
  );

  final AuthService _auth;
  final AiRepository _aiRepo;
  final BucketRepository _bucketRepo;
  final ProfileRepository _profileRepo;
  final TierService _tierService;
  final LocalStore _local = Get.find<LocalStore>();

  // Rating nudge tuning [feedback-nudges]. After this many answers we may show
  // a soft, frequency-capped rating sheet.
  static const _ratingPromptAfter = 3;
  static const _ratingCooldownDays = 14;

  final composer = TextEditingController();
  final RxBool hasText = false.obs;

  final RxList<AiChatTurn> turns = <AiChatTurn>[].obs;
  final RxInt nodeCount = 0.obs;
  final Rxn<Profile> profile = Rxn<Profile>();
  final Rx<SubscriptionTier> _tier = SubscriptionTier.free.obs;

  // Optional bucket scope passed from a bucket's "Ask AI" entry point. Empty =>
  // the whole active-bucket scope (resolved server-side).
  final List<String> _scopeBucketIds = <String>[];

  // In-flight answer state.
  final Rx<AnswerPhase> phase = AnswerPhase.idle.obs;
  final RxString streamText = ''.obs;
  final RxList<RagCitation> liveCitations = <RagCitation>[].obs;
  final RxnString liveModel = RxnString();
  final RxnString liveInteractionId = RxnString();
  final RxnString answerError = RxnString();
  final RxBool offline = false.obs;

  /// Count of completed AI answers this session — drives the rating nudge.
  final RxInt answeredCount = 0.obs;

  /// Learned Aura style directives (human-readable) for the Tune Aura sheet.
  final RxList<String> auraDirectives = <String>[].obs;
  final RxBool prefsLoading = false.obs;

  String _lastQuestion = '';
  Timer? _typeTimer;

  TierGate get gate => TierGate(_tier.value);
  bool get answering => phase.value != AnswerPhase.idle;
  bool get showSuggestions =>
      turns.isEmpty && !answering && answerError.value == null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['bucket_ids'] is List) {
      _scopeBucketIds
        ..clear()
        ..addAll((args['bucket_ids'] as List).map((e) => e.toString()));
    }
    composer.addListener(() => hasText.value = composer.text.trim().isNotEmpty);
    _hydrate();
  }

  Future<void> _hydrate() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      setSuccess();
      return;
    }
    setLoading();
    try {
      final results = await Future.wait([
        _profileRepo.fetchSubscription(userId),
        _profileRepo.fetchProfile(userId),
        _bucketRepo.fetchActiveBuckets(userId),
        _bucketRepo.fetchAllHeatStats(userId),
      ]);
      final sub = results[0] as Subscription?;
      final p = results[1] as Profile?;
      final active = results[2] as List<Bucket>;
      final heat = results[3] as Map<String, BucketHeatStats>;

      profile.value = p;
      _tier.value = _resolveTier(sub, p);
      _tierService.setTier(_tier.value);
      nodeCount.value = active.fold<int>(
        0,
        (sum, b) => sum + (heat[b.id]?.nodeCount ?? 0),
      );
      setSuccess();
    } on RepoException catch (e) {
      offline.value = e.isOffline;
      setSuccess(); // the thread is usable even if scope/profile failed to load
    }
  }

  /// Downgraded = currently free but previously premium [B5] — mirrors the
  /// server `ai_gate_check`. The DB `subscriptions.tier` is only free/premium.
  SubscriptionTier _resolveTier(Subscription? sub, Profile? p) {
    if (sub?.tier == SubscriptionTier.premium) return SubscriptionTier.premium;
    if (p?.hadPremium == true) return SubscriptionTier.downgraded;
    return SubscriptionTier.free;
  }

  // ----------------------------------------------------------- gating UI --

  /// Free monthly AI requests used this period [D-AI-4].
  int get requestsUsed {
    final p = profile.value;
    if (p == null) return 0;
    return p.aiUsagePeriod == _currentPeriod() ? p.aiRequestsMonth : 0;
  }

  String get quotaLabel => '$requestsUsed/50';
  int get creditBalance => profile.value?.aiCreditBalance ?? 0;

  /// Non-null → composer is locked with this reason; null → composer is open.
  String? get composerLockReason {
    if (gate.isDowngraded) return 'AI unavailable — resubscribe to continue';
    if (gate.isFree && requestsUsed >= 50) return 'Monthly AI limit reached';
    return null;
  }

  bool get freeQuotaLock => gate.isFree && requestsUsed >= 50;

  // --------------------------------------------------------------- intents --

  void onSuggestedPrompt(String text) {
    composer.text = text;
    send();
  }

  Future<void> send() async {
    final text = composer.text.trim();
    if (text.isEmpty || answering) return;
    if (composerLockReason != null) {
      RecallHaptics.light();
      Get.toNamed(Routes.paywall);
      return;
    }
    RecallHaptics.selection();
    _lastQuestion = text;
    composer.clear();
    turns.add(AiChatTurn.user(text));
    _track('ai_chat_sent');
    await _ask(spendCredit: false);
  }

  /// Re-run the last question (inline retry chip after a transient failure).
  Future<void> retryLast() => _ask(spendCredit: false);

  /// "Continue with 1 credit" — explicit credit spend during a premium cooldown.
  Future<void> continueWithCredit() async {
    if (Get.isBottomSheetOpen ?? false) Get.back();
    _track('ai_credit_used');
    await _ask(spendCredit: true);
  }

  void buyCredits() {
    if (Get.isBottomSheetOpen ?? false) Get.back();
    Get.toNamed(Routes.paywall);
  }

  Future<void> regenerate() async {
    if (answering || turns.isEmpty) return;
    if (turns.last.role == AiTurnRole.ai) turns.removeLast();
    RecallHaptics.selection();
    await _ask(spendCredit: false);
  }

  void stop() {
    if (phase.value != AnswerPhase.streaming) return;
    _typeTimer?.cancel();
    _finishAnswer(streamText.value);
  }

  void copyAnswer(String text) {
    Clipboard.setData(ClipboardData(text: text));
    RecallHaptics.selection();
  }

  void onSourceTap(RagCitation citation) {
    if (citation.nodeId.isEmpty) return;
    RecallHaptics.selection();
    Get.toNamed(Routes.node, arguments: {'node_id': citation.nodeId});
  }

  // --------------------------------------------------------------- network --

  Future<void> _ask({required bool spendCredit}) async {
    answerError.value = null;
    offline.value = false;
    phase.value = AnswerPhase.searching;
    streamText.value = '';
    try {
      final res = await _aiRepo.ragChat(
        question: _lastQuestion,
        bucketIds: _scopeBucketIds,
        spendCredit: spendCredit,
      );
      liveCitations.assignAll(res.citations);
      liveModel.value = res.model;
      liveInteractionId.value = res.interactionId;
      phase.value = AnswerPhase.streaming;
      _startTyping(res.answer);
    } on RepoException catch (e) {
      phase.value = AnswerPhase.idle;
      _handleError(e);
    }
  }

  void _handleError(RepoException e) {
    switch (e.code) {
      case RepoErrorCode.aiCooldown:
        _openCooldownSheet(e.extra);
      case RepoErrorCode.insufficientCredits:
        _openCooldownSheet(e.extra); // sheet falls back to "Buy credits"
      case RepoErrorCode.premiumRequired:
        _tier.value = SubscriptionTier.downgraded;
        _track('ai_chat_quota_hit');
      case RepoErrorCode.aiQuotaExceeded:
        unawaited(_refreshProfile());
        _track('ai_chat_quota_hit');
      case RepoErrorCode.offline:
        offline.value = true;
        answerError.value = "You're offline — connect to ask your notes.";
      default:
        answerError.value = 'Couldn\u2019t reach the model — try again';
    }
  }

  void _startTyping(String full) {
    _typeTimer?.cancel();
    if (_reduceMotion || full.isEmpty) {
      _finishAnswer(full);
      return;
    }
    streamText.value = '';
    var i = 0;
    _typeTimer = Timer.periodic(_kTypeStep, (t) {
      i++;
      if (i >= full.length) {
        streamText.value = full;
        t.cancel();
        _finishAnswer(full);
      } else {
        streamText.value = full.substring(0, i);
      }
    });
  }

  void _finishAnswer(String text) {
    turns.add(AiChatTurn.ai(
      text: text,
      citations: liveCitations.toList(),
      model: liveModel.value,
      interactionId: liveInteractionId.value,
    ));
    phase.value = AnswerPhase.idle;
    streamText.value = '';
    liveCitations.clear();
    liveModel.value = null;
    liveInteractionId.value = null;
    answeredCount.value += 1;
    unawaited(_refreshProfile());
    unawaited(_maybePromptRating());
  }

  /// Most recent AI turn's interaction id (for attaching session feedback).
  String? get _lastInteractionId {
    for (final t in turns.reversed) {
      if (!t.isUser && t.interactionId != null) return t.interactionId;
    }
    return null;
  }

  /// Soft, frequency-capped rating nudge. Never blocks the thread; silently
  /// no-ops if recently shown, already done, or the user rated positively.
  Future<void> _maybePromptRating() async {
    if (answeredCount.value < _ratingPromptAfter) return;
    if (answering) return;
    if (!_local.isEnabled) return;
    try {
      if (await _local.auraRatingMeta('done') == 'true') return;
      final lastRaw = await _local.auraRatingMeta('last_prompted_at');
      final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
      if (last != null &&
          DateTime.now().difference(last).inDays < _ratingCooldownDays) {
        return;
      }
      await _local.setAuraRatingMeta(
          'last_prompted_at', DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      return;
    }
    _showRatingSheet();
  }

  void _showRatingSheet() {
    final ctx = Get.context;
    if (ctx == null) return;
    AuraRatingSheet.show(
      onSubmit: (rating, text) async {
        await submitRatingFeedback(rating, text);
      },
    );
  }

  /// Session-level rating + optional suggestion from the rating nudge.
  Future<void> submitRatingFeedback(int rating, String text) async {
    final sign = rating >= 4 ? 1 : (rating <= 2 ? -1 : 0);
    final trimmed = text.trim();
    final lastId = _lastInteractionId;
    if (trimmed.isNotEmpty) {
      await sendSuggestion(trimmed, rating: sign, interactionId: lastId);
    } else if (sign != 0 && lastId != null) {
      await _aiRepo.submitRating(lastId, sign);
    }
    // A happy rating ends the nudge for good; otherwise the cooldown applies.
    if (sign == 1) {
      try {
        await _local.setAuraRatingMeta('done', 'true');
      } catch (_) {}
    }
  }

  /// Thumbs feedback on an AI answer [D-AI-6]. Toggles off when tapped again.
  /// Best-effort: a failed/queued rating never disrupts the thread.
  Future<void> rateTurn(AiChatTurn turn, int rating) async {
    final id = turn.interactionId;
    if (id == null) return;
    final next = turn.rating == rating ? 0 : rating;
    turn.rating = next;
    turns.refresh();
    RecallHaptics.selection();
    // Offline-queued + best-effort — the structured signal is non-critical.
    await _aiRepo.submitRating(id, next);
  }

  /// Send a free-text suggestion → per-user personalization [D-AI-8]. Returns a
  /// human-readable acknowledgment of what Aura learned (offline-queued safe).
  Future<String?> sendSuggestion(String suggestion,
      {int rating = 0, String? interactionId}) async {
    final text = suggestion.trim();
    if (text.isEmpty) return null;
    final directives =
        await _aiRepo.submitSuggestion(text, rating: rating, interactionId: interactionId);
    if (directives == null) return null;
    if (directives.isNotEmpty) {
      auraDirectives.assignAll(AuraPrefs.describe(directives));
    }
    return AuraPrefs.acknowledge(directives);
  }

  /// Load the user's learned Aura preferences for the Tune Aura sheet.
  Future<void> loadAuraPrefs() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    prefsLoading.value = true;
    try {
      final prefs = await _aiRepo.fetchPreferences(userId);
      auraDirectives.assignAll(
        prefs == null ? const [] : AuraPrefs.describe(prefs.styleDirectives),
      );
    } on RepoException catch (_) {
      // Transparency view is best-effort; leave the last known directives.
    } finally {
      prefsLoading.value = false;
    }
  }

  /// Forget everything Aura has learned for this user.
  Future<void> clearAuraPrefs() async {
    RecallHaptics.light();
    auraDirectives.clear();
    try {
      await _aiRepo.clearPreferences();
    } on RepoException catch (_) {
      // Best-effort; the local view already reflects the cleared state.
    }
  }

  Future<void> _refreshProfile() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      profile.value = await _profileRepo.fetchProfile(userId) ?? profile.value;
    } on RepoException catch (_) {
      // counters refresh is best-effort; the server stays authoritative.
    }
  }

  void _openCooldownSheet(Map<String, dynamic>? extra) {
    final until = _parseCooldown(extra);
    Get.bottomSheet(
      AiCooldownSheet(
        cooldownUntil: until,
        creditBalance: creditBalance,
        onContinue: continueWithCredit,
        onBuyCredits: buyCredits,
      ),
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
    );
  }

  DateTime? _parseCooldown(Map<String, dynamic>? extra) {
    final raw = extra?['cooldown_until'];
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return profile.value?.aiCooldownUntil?.toLocal();
  }

  String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  bool get _reduceMotion =>
      PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

  void _track(String event) {
    if (!_auth.analyticsOptIn) return;
    debugPrint('analytics:$event'); // provider-agnostic stub [D-OBS-2]
  }

  @override
  void onClose() {
    _typeTimer?.cancel();
    composer.dispose();
    super.onClose();
  }
}
