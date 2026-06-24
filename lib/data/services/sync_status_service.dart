// Recall · SyncStatusService. The single reactive source the UI binds to for
// offline/sync state [D-OFF-1]: connectivity, whether the server has fresher
// data (drives the "Updates available — tap to refresh" nudge), in-flight sync,
// and the offline review backlog. It holds no product truth — only UI signals.
//
// Nudge timing rule: never auto-refresh mid-interaction. While an interaction
// (e.g. an active review session) is open, a discovered update is deferred and
// only surfaced once the interaction ends (sprint edge case: reconnect
// mid-review → defer the nudge until the session ends).

import 'package:get/get.dart';

class SyncStatusService extends GetxService {
  final RxBool isOffline = false.obs;
  final RxBool hasUpdates = false.obs;
  final RxBool isSyncing = false.obs;
  final RxInt pendingCount = 0.obs;

  int _interactionDepth = 0;
  bool _deferredUpdates = false;

  bool get isInteracting => _interactionDepth > 0;

  void setOffline(bool value) => isOffline.value = value;

  void setSyncing(bool value) => isSyncing.value = value;

  void setPendingCount(int value) => pendingCount.value = value < 0 ? 0 : value;

  /// Signals that the server has data newer than the cache. Deferred while an
  /// interaction is open so we never pull content out from under the user.
  void markUpdatesAvailable() {
    if (isInteracting) {
      _deferredUpdates = true;
      return;
    }
    hasUpdates.value = true;
  }

  /// Cleared when the user taps to refresh (the screen reloads its cache).
  void clearUpdates() {
    _deferredUpdates = false;
    hasUpdates.value = false;
  }

  /// Open an interaction window that suppresses the nudge (e.g. review session).
  void beginInteraction() => _interactionDepth++;

  /// Close an interaction window; flush a deferred nudge if one was discovered.
  void endInteraction() {
    if (_interactionDepth > 0) _interactionDepth--;
    if (_interactionDepth == 0 && _deferredUpdates) {
      _deferredUpdates = false;
      hasUpdates.value = true;
    }
  }
}
