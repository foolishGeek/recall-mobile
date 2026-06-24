import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/node_controller.dart';

class NodeView extends GetView<NodeController> {
  const NodeView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Node detail');
}
