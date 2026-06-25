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
import '../controller/shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.currentTab.value;
      return RecallScaffold(
        activeTab: tab,
        onTabChange: controller.onTabSelected,
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
