import 'package:get/get.dart';

import '../controller/empty_controller.dart';

class EmptyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmptyController());
  }
}
