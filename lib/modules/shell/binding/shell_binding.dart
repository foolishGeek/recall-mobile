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
    Get.lazyPut(() => ShellController());
    Get.lazyPut(() => TodayController());
    Get.lazyPut(() => BucketsController());
    Get.lazyPut(() => QuizHomeController(
          Get.find(),
          Get.find(),
          Get.find(),
          Get.find(),
        ));
    Get.lazyPut(() => InsightsController());
    Get.lazyPut(() => YouController());
  }
}
