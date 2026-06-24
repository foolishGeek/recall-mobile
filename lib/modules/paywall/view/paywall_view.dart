import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/paywall_controller.dart';

class PaywallView extends GetView<PaywallController> {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Paywall');
}
