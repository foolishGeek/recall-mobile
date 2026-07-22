// Recall · SettingsController. Every row is schema-backed: prefs PATCH the
// granted `profiles` columns (00003), subscription/credits are server truth, and
// analytics opt-in is the master switch for Sentry [D-OBS-1]. No product logic
// here — writes are optimistic with revert-on-failure (scope=settings). Account
// export/delete + subscription I/O live in settings_controller_actions.dart.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/config/limits_config.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/utils/memory_strength.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/utils/recall_time.dart';
import '../../../data/local/local_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/repo_exception.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../data/services/sync_status_service.dart';
import '../../../data/services/tier_service.dart';

part 'settings_controller_actions.dart';

/// Selectable cooling-period durations (days) for the Review default [S24].
const List<int> kCoolingDayOptions = [1, 3, 7, 14, 30];

/// Daily review-limit range (writes session_size_override). Free clamps to 8 in
/// the engine [D-ENG-3]; the editor still lets premium pick up to 30.
const int kDailyLimitMin = 4;
const int kDailyLimitMax = 30;
const int kDailyLimitStep = 2;

/// Reminder-style wire values + human readout. The wire values are unchanged
/// (daily/3xwk/weekly) but now express *intensity* — they map to drop_intensity()
/// on the backend (00049): weekly=Gentle, 3xwk=Standard, daily=Persistent.
/// Ordered gentle → persistent for the picker.
const List<(String, String, String)> kFrequencyOptions = [
  ('weekly', 'Gentle', 'An occasional nudge'),
  ('3xwk', 'Standard', 'A balanced reminder rhythm'),
  ('daily', 'Persistent', 'Keeps nudging until you review'),
];

class SettingsController extends BaseController {
  SettingsController(
    this._profiles,
    this._auth,
    this._revenueCat,
    this._tier,
    this._theme,
    this._syncStatus,
    this._notifications,
  );

  final ProfileRepository _profiles;
  final AuthService _auth;
  final RevenueCatService _revenueCat;
  final TierService _tier;
  final ThemeService _theme;
  final SyncStatusService _syncStatus;
  final NotificationService _notifications;

  // ── State (server-authoritative + store) ──────────────────────────────────
  final Rxn<Profile> profile = Rxn<Profile>();
  final Rxn<Subscription> subscription = Rxn<Subscription>();
  final Rx<SubscriptionTier> tier = SubscriptionTier.free.obs;
  final RxList<StoreProduct> creditProducts = <StoreProduct>[].obs;
  final Rxn<ExportStatus> exportStatus = Rxn<ExportStatus>();
  final Rxn<SchedulingPrefs> schedulingPrefs = Rxn<SchedulingPrefs>();
  final RxnString appVersion = RxnString();

  // Transient busy flags (per-action so rows stay independent).
  final RxBool exporting = false.obs;
  final RxBool deleting = false.obs;
  final RxBool restoring = false.obs;
  final RxBool buyingCredits = false.obs;

  /// Inline error on the Export row (cleared on retry).
  final RxnString exportError = RxnString();

  /// Quiet, transient line for pref/IO errors (auto-clears).
  final RxnString notice = RxnString();

  // ── Tier ──────────────────────────────────────────────────────────────────
  TierGate get gate => TierGate(tier.value);
  bool get isPremium => tier.value == SubscriptionTier.premium;
  bool get isDowngraded => tier.value == SubscriptionTier.downgraded;
  bool get isFree => tier.value == SubscriptionTier.free;

  /// Config-driven temporary free (`limits_profile=relaxed`).
  bool get suppressPaywall =>
      Get.isRegistered<LimitsConfig>() && Get.find<LimitsConfig>().isRelaxed;

  bool get isOffline => _syncStatus.isOffline.value;

  // ── Derived pref values / labels (presentation only) ──────────────────────
  bool get pushOptIn => profile.value?.pushOptIn ?? false;

  String get dropFrequency => profile.value?.dropFrequency ?? 'daily';

  /// Short name (e.g. "Persistent") for the collapsed Settings row.
  String get frequencyLabel {
    for (final o in kFrequencyOptions) {
      if (o.$1 == dropFrequency) return o.$2;
    }
    return 'Standard';
  }

  String? get quietHoursStart => profile.value?.quietHoursStart;
  String? get quietHoursEnd => profile.value?.quietHoursEnd;
  bool get hasQuietHours =>
      quietHoursStart != null &&
      quietHoursEnd != null &&
      quietHoursStart != quietHoursEnd;
  String get quietHoursLabel => hasQuietHours
      ? '${_hm(quietHoursStart!)} — ${_hm(quietHoursEnd!)}'
      : 'Off';

  bool get hapticsOnDrop => profile.value?.hapticsOnDrop ?? true;
  bool get analyticsOptIn => profile.value?.analyticsOptIn ?? true;

  /// Cooling default in whole days (nearest option), 1 when unparseable.
  int get coolingDays {
    final d = profile.value?.defaultCoolingPeriodDuration;
    if (d == null) return 1;
    final days = (d.inHours / 24).round();
    return days < 1 ? 1 : days;
  }

  String get coolingLabel =>
      coolingDays == 1 ? '1 day' : '$coolingDays days';

  int? get sessionSizeOverride => profile.value?.sessionSizeOverride;
  String get dailyLimitLabel =>
      sessionSizeOverride == null ? 'Default' : '$sessionSizeOverride cards';

  String get theme => _theme.current;
  String get themeLabel => theme.toUpperCase();

  int get creditBalance => profile.value?.aiCreditBalance ?? 0;

  // ── Memory strength (desired retention) ───────────────────────────────────
  /// Effective retention (0..1) used for scheduling; 0.90 until loaded.
  double get memoryStrength => schedulingPrefs.value?.effective ?? 0.90;
  String get memoryStrengthLabel => memoryStrengthLabelFor(memoryStrength);

  StoreProduct? get credits100 =>
      _creditProduct(RevenueCatService.credits100ProductId);
  StoreProduct? get credits500 =>
      _creditProduct(RevenueCatService.credits500ProductId);

  /// "renews 14 Jul" / "expires 14 Jul" (mirrors paywall_controller).
  String? get renewsLabel {
    final d = subscription.value?.expiresAt?.toLocal();
    if (d == null) return null;
    final verb = subscription.value?.willRenew == true ? 'renews' : 'expires';
    return '$verb ${d.day} ${_kMonthAbbr[(d.month - 1).clamp(0, 11)]}';
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    setLoading();
    try {
      final r = await _profiles.refreshEntitlement(userId);
      _syncStatus.setOffline(false);
      profile.value = r.profile;
      subscription.value = r.subscription;
      _tier.applyEntitlement(subscription: r.subscription, profile: r.profile);
      tier.value = _tier.tier;

      final p = r.profile;
      if (p != null) {
        // Sync the analytics gate + theme with server truth on load.
        _auth.setAnalyticsOptIn(p.analyticsOptIn);
        if (p.theme != _theme.current) await _theme.apply(p.theme);
      }
    } on RepoException catch (e) {
      if (e.isOffline) {
        _syncStatus.setOffline(true);
        setError("You're offline. Check your connection and try again.");
      } else {
        setError(e.message);
      }
      return;
    }

    setSuccess();
    _loadAux(); // version + export status + credit products (best-effort)
    _track('settings_viewed', {'tier': tier.value.name});
  }

  /// Best-effort extras that must never block or fail the screen.
  Future<void> _loadAux() async {
    PackageInfo.fromPlatform().then((info) {
      if (!isClosed) {
        // Match pubspec `version: x.y.z+build` (name + versionCode).
        appVersion.value = '${info.version}+${info.buildNumber}';
      }
    }).catchError((_) {});

    if (!isOffline) {
      _profiles.fetchExportStatus().then((s) {
        if (!isClosed) exportStatus.value = s;
      }).catchError((_) {});

      _profiles.getSchedulingPrefs().then((p) {
        if (!isClosed) schedulingPrefs.value = p;
      }).catchError((_) {});
    }

    if (isPremium) {
      _revenueCat.fetchCreditProducts().then((list) {
        if (!isClosed) creditProducts.assignAll(list);
      }).catchError((_) {});
    }
  }

  Future<void> reload() async => _load();

  // ── Preference intents (optimistic write + revert on failure) ─────────────

  /// Master push switch. Turning on requires OS permission (and a token); if the
  /// user denies it, we leave the toggle off and nudge toward system settings.
  /// This is the recovery path for anyone who declined push during onboarding.
  Future<void> togglePush(bool value) async {
    if (value == pushOptIn) return;
    if (value) {
      final granted = await _notifications.requestPushPermission();
      if (!granted) {
        _notify('Turn on notifications in system settings to get Drops.');
        profile.refresh(); // keep the toggle visually off
        return;
      }
      await _notifications.registerDeviceToken();
    }
    await _patch({'push_opt_in': value},
        profile.value?.copyWith(pushOptIn: value));
  }

  /// Sets the user's default memory strength (desired retention). Optimistic;
  /// reverts on failure. Backend clamps to the safe band.
  Future<void> setMemoryStrength(double retention) async {
    if ((retention - memoryStrength).abs() < 0.001) return;
    final prev = schedulingPrefs.value;
    schedulingPrefs.value = SchedulingPrefs(
      appDefault: prev?.appDefault,
      userValue: retention,
      bucketValue: prev?.bucketValue,
      effective: retention,
    );
    RecallHaptics.selection();
    try {
      schedulingPrefs.value =
          await _profiles.setSchedulingPrefs(targetRetention: retention);
    } on RepoException catch (e, st) {
      schedulingPrefs.value = prev;
      _onWriteFailed(e, st);
    }
  }

  Future<void> setDropFrequency(String value) async {
    if (value == dropFrequency) return;
    await _patch({'drop_frequency': value},
        profile.value?.copyWith(dropFrequency: value));
  }

  Future<void> setQuietHours(String? start, String? end) async {
    // start == end ⇒ "no quiet hours" (clear both).
    final clear = start == null || end == null || start == end;
    await _patch(
      {
        'quiet_hours_start': clear ? null : start,
        'quiet_hours_end': clear ? null : end,
      },
      profile.value?.copyWith(
        quietHoursStart: clear ? null : start,
        quietHoursEnd: clear ? null : end,
      ),
    );
  }

  Future<void> setCoolingDays(int days) async {
    if (days == coolingDays) return;
    final interval = days == 1 ? '1 day' : '$days days';
    await _patch({'default_cooling_period': interval},
        profile.value?.copyWith(defaultCoolingPeriod: interval));
  }

  Future<void> setDailyLimit(int value) async {
    if (value == sessionSizeOverride) return;
    await _patch({'session_size_override': value},
        profile.value?.copyWith(sessionSizeOverride: value));
  }

  Future<void> toggleHaptics(bool value) async {
    await _patch({'haptics_on_drop': value},
        profile.value?.copyWith(hapticsOnDrop: value));
  }

  /// Theme is local-first (instant, survives restart) + server-persisted.
  Future<void> setTheme(String value) async {
    if (value == theme) return;
    final prevTheme = theme;
    final prev = profile.value;
    await _theme.apply(value);
    profile.value = prev?.copyWith(theme: value);

    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      profile.value = await _profiles.updatePreferences(userId, {'theme': value});
    } on RepoException catch (e, st) {
      await _theme.apply(prevTheme);
      profile.value = prev;
      _onWriteFailed(e, st);
    }
  }

  /// Analytics opt-in is the master Sentry switch — flip the gate immediately so
  /// opt-out drops events at once [D-OBS-1], then persist.
  Future<void> toggleAnalytics(bool value) async {
    final prev = profile.value;
    _auth.setAnalyticsOptIn(value);
    profile.value = prev?.copyWith(analyticsOptIn: value);

    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      profile.value =
          await _profiles.updatePreferences(userId, {'analytics_opt_in': value});
    } on RepoException catch (e, st) {
      _auth.setAnalyticsOptIn(prev?.analyticsOptIn ?? true);
      profile.value = prev;
      _onWriteFailed(e, st);
    }
  }

  Future<void> _patch(Map<String, dynamic> changes, Profile? optimistic) async {
    final userId = _auth.currentUserId;
    if (userId == null || optimistic == null) return;
    final prev = profile.value;
    profile.value = optimistic;
    try {
      profile.value = await _profiles.updatePreferences(userId, changes);
    } on RepoException catch (e, st) {
      profile.value = prev;
      _onWriteFailed(e, st);
    }
  }

  void _onWriteFailed(RepoException e, StackTrace st) {
    _notify(e.isOffline
        ? "You're offline — that change wasn't saved."
        : "Couldn't save that change — try again.");
    _capture(e, st, 'pref_write');
  }

  // ── Shared helpers (used here + in the actions part) ──────────────────────
  StoreProduct? _creditProduct(String id) {
    for (final p in creditProducts) {
      if (RevenueCatService.matchesProductId(p.identifier, id)) return p;
    }
    return null;
  }

  String _hm(String time) {
    if (time.length < 5) return time;
    final h = int.tryParse(time.substring(0, 2));
    final m = int.tryParse(time.substring(3, 5));
    if (h == null || m == null) return time.substring(0, 5);
    return RecallTime.clock12h(DateTime(2000, 1, 1, h, m));
  }

  void _notify(String message) {
    notice.value = message;
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!isClosed && notice.value == message) notice.value = null;
    });
  }

  void _capture(Object e, StackTrace st, String op) {
    Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (s) {
        s.setTag('feature', 'settings');
        s.setTag('op', op);
      },
    );
  }

  void _track(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(
      Breadcrumb(category: 'analytics', message: name, data: params),
    );
  }
}

const _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
