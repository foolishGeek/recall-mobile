import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/empty_buckets_controller.dart';

class EmptyBucketsView extends GetView<EmptyBucketsController> {
  const EmptyBucketsView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Empty · Buckets');
}
