import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_scaffold.dart';
import '../../insights/view/widgets/insights_empty_body.dart';
import '../controller/empty_insights_controller.dart';

class EmptyInsightsView extends GetView<EmptyInsightsController> {
  const EmptyInsightsView({super.key});

  @override
  Widget build(BuildContext context) => RecallScaffold.bare(
        body: InsightsEmptyBody(
          days: controller.days,
          onStart: controller.startReview,
        ),
      );
}
