import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/bucket_controller.dart';

class BucketView extends GetView<BucketController> {
  const BucketView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Bucket detail');
}
