import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/node_add_controller.dart';

class NodeAddView extends GetView<NodeAddController> {
  const NodeAddView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Add / Edit node');
}
