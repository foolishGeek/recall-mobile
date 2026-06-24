import 'package:get/get.dart';

import '../controller/empty_insights_controller.dart';

class EmptyInsightsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmptyInsightsController());
  }
}
