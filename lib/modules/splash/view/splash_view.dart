import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_mark.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../controller/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecallScaffold.bare(
      body: Center(child: RecallWordmark(size: 44)),
    );
  }
}
