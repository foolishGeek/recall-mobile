import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/empty_today_controller.dart';

class EmptyTodayView extends GetView<EmptyTodayController> {
  const EmptyTodayView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Empty · Today');
}
