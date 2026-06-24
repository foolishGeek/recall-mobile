import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/insights_controller.dart';

class InsightsView extends GetView<InsightsController> {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        child: const PlaceholderBody(title: 'Insights'),
      ),
    );
  }
}
