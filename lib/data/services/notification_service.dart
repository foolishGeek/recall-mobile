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
  bool _listenersReady = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initListeners());
    // Re-register the token whenever a session appears (returning user / login).
    _sessionWorker = ever(_auth.sessionRx, (session) {
      if (session != null) unawaited(registerDeviceToken());
    });
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

  Future<void> _registerToken(String token) async {
    final userId = _auth.currentUserId;
    if (userId == null || token.isEmpty) return;
    try {
      final platform =
          Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
      await _notifications.registerDeviceToken(
        userId: userId,
        platform: platform,
        token: token,
      );
    } catch (e, st) {
      _capture(e, st);
    }
  }

  void _handleForeground(RemoteMessage message) {
    if (message.data['type'] != _dropType) return;
    final dedupeKey = message.data['dedupe_key'] as String?;
    unawaited(onMessageDelivered(dedupeKey));
    _trackDropEvent('drop_received', {'dedupe_key': dedupeKey});
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

  /// Routes the payload's `route` (fallback /today). Deferred to post-frame so a
  /// cold-start (terminated) tap navigates after the app tree is built.
  void _deepLink(String? route) {
    if (_auth.currentUserId == null) return;
    final target = (route == null || route.isEmpty) ? Routes.today : route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.offAllNamed(target);
      } catch (e, st) {
        _capture(e, st);
        try {
          Get.offAllNamed(Routes.today);
        } catch (_) {}
      }
    });
  }

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
    super.onClose();
  }
}
