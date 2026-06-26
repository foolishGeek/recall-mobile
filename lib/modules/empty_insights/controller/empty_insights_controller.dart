import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/recall_haptics.dart';

/// Standalone InsightsEmpty route (deep-link / fallback). In-app, the Insights
/// tab renders the same portrait gate inline so the tab bar stays active. Days
/// can be passed via `Get.arguments['days']`.
class EmptyInsightsController extends BaseController {
  int days = 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['days'] is int) {
      days = args['days'] as int;
    }
    setSuccess();
  }

  void startReview() {
    RecallHaptics.light();
    Get.offAllNamed(Routes.today);
  }
}
