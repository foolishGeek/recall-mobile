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
    // fenix: the shell + tab controllers must survive route disposal. On an
    // offAllNamed('/today') re-entry GetX runs this binding while the outgoing
    // route is still alive (guards skip), then disposes it and deletes these
    // controllers. Without fenix their factories go too, so the next
    // GetView.controller / Get.find throws or falls back to a blank frame. With
    // fenix the factory is retained, so Get.find always recreates on demand.
    if (!Get.isRegistered<ShellController>()) {
      Get.lazyPut(() => ShellController(), fenix: true);
    }
    final shell = Get.find<ShellController>();
    final tab = ShellController.tabForRoute(Get.currentRoute);
    if (tab != null) shell.currentTab.value = tab;

    if (!Get.isRegistered<TodayController>()) {
      Get.lazyPut(() => TodayController(), fenix: true);
    }
    if (!Get.isRegistered<BucketsController>()) {
      Get.lazyPut(() => BucketsController(), fenix: true);
    }
    if (!Get.isRegistered<QuizHomeController>()) {
      Get.lazyPut(
        () => QuizHomeController(
          Get.find(),
          Get.find(),
          Get.find(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InsightsController>()) {
      Get.lazyPut(() => InsightsController(), fenix: true);
    }
    if (!Get.isRegistered<YouController>()) {
      Get.lazyPut(() => YouController(), fenix: true);
    }
  }
}
