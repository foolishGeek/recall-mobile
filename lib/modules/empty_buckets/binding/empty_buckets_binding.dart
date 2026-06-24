import 'package:get/get.dart';

import '../controller/empty_buckets_controller.dart';

class EmptyBucketsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmptyBucketsController());
  }
}
