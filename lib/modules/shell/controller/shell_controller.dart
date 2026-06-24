// Recall · ShellController. Owns the active tab for the five-tab shell. The tab
// routes all resolve to ShellView; the route navigated to drives the initial
// tab, and in-shell taps swap the indexed body (RecallMotion.tabSwap).

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/recall_scaffold.dart';

class ShellController extends GetxController {
  final Rx<RecallTab> currentTab = RecallTab.today.obs;

  @override
  void onInit() {
    super.onInit();
    final tab = tabForRoute(Get.currentRoute);
    if (tab != null) currentTab.value = tab;
  }

  void onTabSelected(RecallTab tab) => currentTab.value = tab;

  static RecallTab? tabForRoute(String route) {
    switch (route) {
      case Routes.today:
        return RecallTab.today;
      case Routes.buckets:
        return RecallTab.buckets;
      case Routes.quiz:
        return RecallTab.quiz;
      case Routes.insights:
        return RecallTab.insights;
      case Routes.you:
        return RecallTab.you;
      default:
        return null;
    }
  }
}
