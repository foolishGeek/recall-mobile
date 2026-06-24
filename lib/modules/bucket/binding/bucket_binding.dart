import 'package:get/get.dart';

import '../controller/bucket_controller.dart';

class BucketBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BucketController());
  }
}
