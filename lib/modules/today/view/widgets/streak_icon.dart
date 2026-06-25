import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StreakIcon extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const StreakIcon({
    super.key,
    required this.color,
    this.width = 17,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/streak-flame.svg',
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
