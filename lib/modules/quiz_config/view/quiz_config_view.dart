import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/quiz_config_controller.dart';

class QuizConfigView extends GetView<QuizConfigController> {
  const QuizConfigView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Quiz config');
}
