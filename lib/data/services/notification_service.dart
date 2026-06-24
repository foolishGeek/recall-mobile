// Recall · NotificationService. S09: OS permission + FCM token registration.
// S16 completes message handlers (delivered/opened) and deep links.

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../models/models.dart';
import '../repositories/notification_repository.dart';
import 'auth_service.dart';

class NotificationService extends GetxService {
  NotificationService(this._auth, this._notifications);

  final AuthService _auth;
  final NotificationRepository _notifications;

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
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'notifications'),
      );
      return false;
    }
  }

  /// Registers/refreshes the device FCM token (device_tokens).
  Future<void> registerDeviceToken() async {
    if (!isFirebaseReady) return;
    final userId = _auth.currentUserId;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final platform =
          Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
      await _notifications.registerDeviceToken(
        userId: userId,
        platform: platform,
        token: token,
      );
    } catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'notifications'),
      );
    }
  }

  /// Records a `delivered` event on FCM data-message receipt. S16 implements.
  Future<void> onMessageDelivered(String dedupeKey) async {
    // TODO(S16): NotificationRepository.recordEvent(delivered, dedupeKey).
  }

  /// Records an `opened` event on notification tap. S16 implements.
  Future<void> onNotificationOpened(String dedupeKey) async {
    // TODO(S16): NotificationRepository.recordEvent(opened, dedupeKey).
  }
}
