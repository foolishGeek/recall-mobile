import 'package:get/get.dart';

import '../controller/empty_today_controller.dart';

class EmptyTodayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmptyTodayController());
  }
}
