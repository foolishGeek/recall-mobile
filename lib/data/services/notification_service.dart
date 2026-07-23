// Recall · NotificationService. S09: OS permission + FCM token registration.
// S16: token refresh, FG/BG message handlers (log `delivered`), notification-tap
// deep link to /today (log `opened`), all gated analytics stubs. Eager permanent
// singleton (registered in main) — self-wires FCM streams in onInit and
// re-registers the token on sign-in. Product logic stays server-side; this only
// renders, logs receipt/open, and routes. [D-EF-10].

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/routes/app_routes.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/recall_colors.dart';
import '../../core/widgets/recall_scaffold.dart';
import '../../modules/shell/controller/shell_controller.dart';
import '../../modules/today/controller/today_controller.dart';
import '../models/models.dart';
import '../repositories/notification_repository.dart';
import 'auth_service.dart';

/// FCM data payload `type` for a Recall Drop (matches compute-due EF).
const String _dropType = 'recall_drop';

class NotificationService extends GetxService {
  NotificationService(this._auth, this._notifications);

  final AuthService _auth;
  final NotificationRepository _notifications;

  Worker? _sessionWorker;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  AppLifecycleListener? _lifecycle;
  bool _listenersReady = false;

  /// Deep-link target captured before the app tree is ready (cold-start tap).
  /// SplashController consumes and clears this once the session is hydrated so
  /// the tap navigates through the normal AuthGate flow instead of racing it.
  String? pendingRoute;

  /// Consumes the pending deep link (returns and clears it). Called by splash.
  String? takePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initListeners());
    // Re-register the token whenever a session appears (returning user / login).
    _sessionWorker = ever(_auth.sessionRx, (session) {
      if (session != null) unawaited(registerDeviceToken());
    });
    // Reliability: whenever the app returns to the foreground, refresh the token
    // if push is already permitted. Catches tokens rotated while backgrounded and
    // permission granted from OS settings — so an opted-in device stays reachable.
    // Never prompts on resume (only registers when already granted).
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refreshTokenIfPermitted()),
    );
  }

  /// Wires FCM streams once and handles a terminated-state tap. No-ops when
  /// Firebase failed to init (e.g. local dev without google-services.json).
  Future<void> _initListeners() async {
    if (!isFirebaseReady || _listenersReady) return;
    _listenersReady = true;
    try {
      unawaited(registerDeviceToken());
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
      _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleOpened(initial);
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// Requests OS notification permission. Returns true when granted.
  Future<bool> requestPushPermission() async {
    if (!isFirebaseReady && Firebase.apps.isEmpty) return false;

    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e, st) {
      _capture(e, st);
      return false;
    }
  }

  /// Ensures an opted-in user actually has the OS permission + a live token.
  /// Covers reinstall / permission-reset: if the grant is missing (and not
  /// permanently denied) we re-prompt, then refresh the token. Idempotent — the
  /// OS shows no dialog when already granted or permanently denied.
  Future<void> ensurePermissionAndToken() async {
    if (!isFirebaseReady) return;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        await registerDeviceToken();
        return;
      }
      if (status.isPermanentlyDenied) return;
      final granted = await requestPushPermission();
      if (granted) {
        await registerDeviceToken();
        // A fresh grant means the user wants Drops — reconcile the master
        // switch so the engine (compute_due_candidates) can actually reach them.
        await _setOptIn(true);
      }
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// User-driven "turn on reminders" primitive (Settings toggle + the Reminders
  /// diagnostic repair). Requests OS permission, writes a live device token, and
  /// sets the account-wide `push_opt_in` flag together — so the flag and the
  /// token can never silently disagree. Returns true when fully enabled.
  Future<bool> enableDrops() async {
    final granted = await requestPushPermission();
    if (!granted) return false;
    await registerDeviceToken();
    await _setOptIn(true);
    return true;
  }

  /// Honest per-user Drop eligibility breakdown for the Settings diagnostic.
  Future<DropDebug> fetchDropDebug() => _notifications.fetchDropDebug();

  /// Best-effort write of the account-wide reminders switch. Never throws — a
  /// failed reconcile just leaves the prior value.
  Future<void> _setOptIn(bool value) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      await _notifications.setPushOptIn(userId: userId, value: value);
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// Refreshes the token only when push is already permitted — safe to call on
  /// every resume without ever showing a permission dialog.
  Future<void> refreshTokenIfPermitted() async {
    if (!isFirebaseReady) return;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) await registerDeviceToken();
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// Registers/refreshes the current device FCM token (device_tokens).
  Future<void> registerDeviceToken() async {
    if (!isFirebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// Upserts the token with a short bounded retry so a transient network blip
  /// never leaves an opted-in device unreachable (the Drop pipeline can only
  /// nudge devices with a live row). Backoff: 0.5s, 2s, 5s.
  Future<void> _registerToken(String token) async {
    final userId = _auth.currentUserId;
    if (userId == null || token.isEmpty) return;
    final platform =
        Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
    const delays = [
      Duration(milliseconds: 500),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        await _notifications.registerDeviceToken(
          userId: userId,
          platform: platform,
          token: token,
        );
        return;
      } catch (e, st) {
        if (attempt == delays.length) {
          _capture(e, st);
          return;
        }
        await Future<void>.delayed(delays[attempt]);
        // Bail out if the session ended mid-retry.
        if (_auth.currentUserId != userId) return;
      }
    }
  }

  void _handleForeground(RemoteMessage message) {
    if (message.data['type'] != _dropType) return;
    final dedupeKey = message.data['dedupe_key'] as String?;
    unawaited(onMessageDelivered(dedupeKey));
    _trackDropEvent('drop_received', {'dedupe_key': dedupeKey});
    _showForegroundBanner(message);
  }

  /// FCM does not display a system notification while the app is foregrounded,
  /// so we surface a tappable, on-brand in-app banner for parity — no extra
  /// plugin needed. Tapping it logs `opened` and deep-links like a real tap.
  void _showForegroundBanner(RemoteMessage message) {
    if (Get.isSnackbarOpen) return;
    final ctx = Get.context;
    final colors = ctx == null ? null : RecallColors.of(ctx);
    final title = message.notification?.title ?? 'Your cards are ready';
    final body = message.notification?.body ??
        'A fresh set is ready to review — tap to open Today.';
    try {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        backgroundColor: colors?.card,
        colorText: colors?.ink,
        onTap: (_) {
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          unawaited(onNotificationOpened(message.data['dedupe_key'] as String?));
          _trackDropEvent('drop_opened', {
            'dedupe_key': message.data['dedupe_key'],
          });
          _deepLink(message.data['route'] as String?);
        },
      );
    } catch (e, st) {
      _capture(e, st);
    }
  }

  void _handleOpened(RemoteMessage message) {
    if (message.data['type'] != _dropType) return;
    final dedupeKey = message.data['dedupe_key'] as String?;
    unawaited(onNotificationOpened(dedupeKey));
    _trackDropEvent('drop_opened', {'dedupe_key': dedupeKey});
    _deepLink(message.data['route'] as String?);
  }

  /// Records a `delivered` event on FCM data-message receipt (foreground).
  Future<void> onMessageDelivered(String? dedupeKey) =>
      _logEvent(NotificationEventType.delivered, dedupeKey);

  /// Records an `opened` event on notification tap.
  Future<void> onNotificationOpened(String? dedupeKey) =>
      _logEvent(NotificationEventType.opened, dedupeKey);

  Future<void> _logEvent(NotificationEventType type, String? dedupeKey) async {
    final userId = _auth.currentUserId;
    if (userId == null || dedupeKey == null || dedupeKey.isEmpty) return;
    try {
      await _notifications.recordEvent(
        userId: userId,
        type: type,
        dedupeKey: dedupeKey,
      );
    } catch (e, st) {
      _capture(e, st);
    }
  }

  /// Routes the payload's `route` (fallback /today) without racing app startup.
  /// - App already in the tab shell: switch to Today in-place (no `offAllNamed`
  ///   re-entry churn) and refresh so the freshly-matured cards show.
  /// - App not yet in the shell (cold start / still on splash): stash the target
  ///   as a pending deep link for SplashController to honor after hydration.
  /// - Authed but outside the shell (edge case): fall back to `offAllNamed`.
  void _deepLink(String? route) {
    if (_auth.currentUserId == null) return;
    final target = (route == null || route.isEmpty) ? Routes.today : route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_isInShell) {
          Get.find<ShellController>().onTabSelected(RecallTab.today);
          if (Get.isRegistered<TodayController>()) {
            unawaited(Get.find<TodayController>().reload());
          }
          return;
        }
        if (!Get.isRegistered<ShellController>()) {
          pendingRoute = target;
          return;
        }
        Get.offAllNamed(target);
      } catch (e, st) {
        _capture(e, st);
        try {
          Get.offAllNamed(Routes.today);
        } catch (_) {}
      }
    });
  }

  /// True when the tab shell is live and currently the active route.
  bool get _isInShell =>
      Get.isRegistered<ShellController>() &&
      ShellController.tabForRoute(Get.currentRoute) != null;

  /// Provider-agnostic analytics stub, gated by analytics opt-in [D-OBS-2].
  void _trackDropEvent(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(
      Breadcrumb(category: 'analytics', message: name, data: params),
    );
  }

  void _capture(Object e, StackTrace st) {
    unawaited(Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) => scope.setTag('feature', 'notifications'),
    ));
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    _lifecycle?.dispose();
    super.onClose();
  }
}
