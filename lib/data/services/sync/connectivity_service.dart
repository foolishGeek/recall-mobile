// Recall · ConnectivityService. Listens to network changes (connectivity_plus),
// mirrors them into SyncStatusService.isOffline, and triggers a queue drain when
// the device comes back online [D-OFF-1]. Connectivity only reports interface
// availability — actual reachability is proven by the drain itself, which stops
// cleanly and stays queued if the network is not really usable.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import 'sync_service.dart';
import 'sync_status_service.dart';

class ConnectivityService extends GetxService {
  ConnectivityService(this._status, this._sync);

  final SyncStatusService _status;
  final SyncService _sync;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      // Assume online if the platform check fails; the drain self-corrects.
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    _status.setOffline(!online);
    final cameOnline = online && !_online;
    _online = online;
    if (cameOnline) unawaited(_sync.drain());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
