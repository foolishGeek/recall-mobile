import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/quiz_results_controller.dart';

class QuizResultsView extends GetView<QuizResultsController> {
  const QuizResultsView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Quiz results');
}
