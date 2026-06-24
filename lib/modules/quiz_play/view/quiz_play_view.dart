import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/quiz_play_controller.dart';

class QuizPlayView extends GetView<QuizPlayController> {
  const QuizPlayView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Quiz play');
}
