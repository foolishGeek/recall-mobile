import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/empty_insights_controller.dart';

class EmptyInsightsView extends GetView<EmptyInsightsController> {
  const EmptyInsightsView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Empty · Insights');
}
