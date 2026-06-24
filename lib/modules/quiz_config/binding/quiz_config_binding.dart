import 'package:get/get.dart';

import '../controller/quiz_config_controller.dart';

class QuizConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizConfigController());
  }
}
