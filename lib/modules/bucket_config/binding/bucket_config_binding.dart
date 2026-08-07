import 'package:get/get.dart';

/// The Bucket config surface reuses the live BucketController from the detail
/// screen sitting beneath it in the stack (single source of truth for cooling /
/// memory / save state). Nothing new to register — this binding is a no-op so
/// the route table stays uniform.
class BucketConfigBinding extends Bindings {
  @override
  void dependencies() {}
}
