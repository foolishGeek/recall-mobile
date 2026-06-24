import 'package:get/get.dart';

import '../controller/quiz_play_controller.dart';

class QuizPlayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizPlayController());
  }
}
