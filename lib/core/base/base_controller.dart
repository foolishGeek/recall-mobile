// Recall · BaseController. Shared controller base exposing a reactive ViewState
// so views render loading / success / error via RecallStateView. Feature
// controllers extend this and call the helpers from their intent methods.

import 'package:get/get.dart';

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
}
