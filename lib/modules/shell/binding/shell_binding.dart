// Recall · ShellBinding. DI for the shell + the five tab controllers.

import 'package:get/get.dart';

import '../../buckets/controller/buckets_controller.dart';
import '../../insights/controller/insights_controller.dart';
import '../../quiz_home/controller/quiz_home_controller.dart';
import '../../today/controller/today_controller.dart';
import '../../you/controller/you_controller.dart';
import '../controller/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    // Eager put (not lazyPut): ShellView's GetView resolves this on the first
    // frame; lazy registration races hot reload and offAllNamed tab re-entry.
    final shell = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : Get.put(ShellController());
    final tab = ShellController.tabForRoute(Get.currentRoute);
    if (tab != null) shell.currentTab.value = tab;

    if (!Get.isRegistered<TodayController>()) {
      Get.lazyPut(() => TodayController());
    }
    if (!Get.isRegistered<BucketsController>()) {
      Get.lazyPut(() => BucketsController());
    }
    if (!Get.isRegistered<QuizHomeController>()) {
      Get.lazyPut(() => QuizHomeController(
            Get.find(),
            Get.find(),
            Get.find(),
            Get.find(),
          ));
    }
    if (!Get.isRegistered<InsightsController>()) {
      Get.lazyPut(() => InsightsController());
    }
    if (!Get.isRegistered<YouController>()) {
      Get.lazyPut(() => YouController());
    }
  }
}
