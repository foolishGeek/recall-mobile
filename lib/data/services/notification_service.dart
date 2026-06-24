// Recall · NotificationService (stub — implemented in S16). Will own FCM token
// registration and writing notification_events `delivered`/`opened` [D-EF-10]
// on message receipt / tap. S03 declares the seam only.

import 'package:get/get.dart';

class NotificationService extends GetxService {
  /// Registers/refreshes the device FCM token (device_tokens). S16 implements.
  Future<void> registerDeviceToken(String token) async {
    // TODO(S16): upsert device_tokens(platform, token, last_seen_at).
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
