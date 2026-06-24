// Recall · RecallStateView. Dumb wrapper that maps a ViewState to the shared
// loading / error / content widgets. Keeps views free of if/else over status.
//
//   Obx(() => RecallStateView(
//     state: controller.viewState.value,
//     onRetry: controller.load,
//     child: ...,
//   ))

import 'package:flutter/material.dart';

import '../base/view_state.dart';
import 'recall_error_card.dart';
import 'recall_skeleton.dart';

class RecallStateView extends StatelessWidget {
  final ViewState state;
  final Widget child;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const RecallStateView({
    super.key,
    required this.state,
    required this.child,
    this.loading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ViewState.loading:
      case ViewState.idle:
        return loading ?? const _DefaultSkeleton();
      case ViewState.error:
        return RecallErrorCard(
          message: errorMessage ?? "Couldn't reach the server — try again",
          onRetry: onRetry,
        );
      case ViewState.success:
        return child;
    }
  }
}

class _DefaultSkeleton extends StatelessWidget {
  const _DefaultSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        RecallSkeleton(height: 22, width: 180),
        SizedBox(height: 14),
        RecallSkeleton(height: 64),
        SizedBox(height: 10),
        RecallSkeleton(height: 64),
      ],
    );
  }
}
