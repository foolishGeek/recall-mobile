// Recall · BaseController. Shared controller base exposing a reactive ViewState
// so views render loading / success / error via RecallStateView. Feature
// controllers extend this and call the helpers from their intent methods.

import 'package:get/get.dart';

import '../../data/services/shared/repo_exception.dart';
import '../../data/services/sync/sync_status_service.dart';
import 'view_state.dart';

abstract class BaseController extends GetxController {
  final Rx<ViewState> _viewState = ViewState.idle.obs;
  final RxnString _errorMessage = RxnString();

  ViewState get viewState => _viewState.value;
  Rx<ViewState> get viewStateRx => _viewState;
  String? get errorMessage => _errorMessage.value;

  void setIdle() {
    _errorMessage.value = null;
    _viewState.value = ViewState.idle;
  }

  void setLoading() {
    _errorMessage.value = null;
    _viewState.value = ViewState.loading;
  }

  void setSuccess() {
    _errorMessage.value = null;
    _viewState.value = ViewState.success;
  }

  void setError([String? message]) {
    _errorMessage.value = message;
    _viewState.value = ViewState.error;
  }

  /// Shared offline / load error mapping used by shell tab controllers.
  void handleLoadError(RepoException e, SyncStatusService sync) {
    if (e.isOffline) {
      sync.setOffline(true);
      setError('You\'re offline. Check your connection and try again.');
    } else {
      setError(e.message);
    }
  }

  /// Per-card soft failure — never breaks the whole screen.
  Future<void> runCardSafe(
    String card,
    RxMap<String, bool> flags,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      flags[card] = false;
    } on RepoException {
      flags[card] = true;
    }
  }
}
