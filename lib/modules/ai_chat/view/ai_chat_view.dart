import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/ai_chat_controller.dart';

class AiChatView extends GetView<AiChatController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'AI chat');
}
