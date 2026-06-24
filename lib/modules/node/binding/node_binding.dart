import 'package:get/get.dart';

import '../controller/node_controller.dart';

class NodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NodeController());
  }
}
