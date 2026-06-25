import 'package:get/get.dart';

import '../controller/quiz_results_controller.dart';

class QuizResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizResultsController(Get.find(), Get.find()));
  }
}
