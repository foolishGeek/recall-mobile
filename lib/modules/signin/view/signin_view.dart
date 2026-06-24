import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../controller/signin_controller.dart';

class SigninView extends GetView<SigninController> {
  const SigninView({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Sign in', showBack: false);
}
