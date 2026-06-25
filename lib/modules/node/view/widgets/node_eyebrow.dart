import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class NodeEyebrow extends StatelessWidget {
  final String bucketName;
  final String typeLabel;
  final String editedAgo;

  const NodeEyebrow({
    super.key,
    required this.bucketName,
    required this.typeLabel,
    required this.editedAgo,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final style = GoogleFonts.jetBrainsMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      color: c.grey500,
      letterSpacing: 0.18,
    );
    return Row(
      children: [
        Text(bucketName.toUpperCase(), style: style),
        _dot(c),
        Text(typeLabel, style: style),
        _dot(c),
        Text('Edited $editedAgo', style: style),
      ],
    );
  }

  Widget _dot(RecallColors c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(color: c.grey400, shape: BoxShape.circle),
        ),
      );
}
