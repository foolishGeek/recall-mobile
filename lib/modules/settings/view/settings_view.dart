import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Settings');
}
