// Recall · ShellView. The five-tab shell: RecallScaffold chrome + the active
// tab body. Body swaps with the 280ms tab-swap cross-fade in RecallScaffold.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_scaffold.dart';
import '../../buckets/view/buckets_view.dart';
import '../../insights/view/insights_view.dart';
import '../../quiz_home/view/quiz_home_view.dart';
import '../../today/view/today_view.dart';
import '../../you/view/you_view.dart';
import '../binding/shell_binding.dart';
import '../controller/shell_controller.dart';

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  /// Hot reload clears GetX controllers without re-running route bindings; ensure
  /// the shell (and tab controllers) are registered before the first Obx read.
  void _ensureRegistered() {
    if (!Get.isRegistered<ShellController>()) {
      ShellBinding().dependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureRegistered();
    return Obx(() {
      // Resolve inside Obx so a hot-reload race never hits GetView.controller
      // after ShellController was cleared mid-frame.
      if (!Get.isRegistered<ShellController>()) {
        return const SizedBox.shrink();
      }
      final shell = Get.find<ShellController>();
      final tab = shell.currentTab.value;
      return RecallScaffold(
        activeTab: tab,
        onTabChange: shell.onTabSelected,
        body: _bodyFor(tab),
      );
    });
  }

  Widget _bodyFor(RecallTab tab) {
    switch (tab) {
      case RecallTab.today:
        return const TodayView();
      case RecallTab.buckets:
        return const BucketsView();
      case RecallTab.quiz:
        return const QuizHomeView();
      case RecallTab.insights:
        return const InsightsView();
      case RecallTab.you:
        return const YouView();
    }
  }
}
