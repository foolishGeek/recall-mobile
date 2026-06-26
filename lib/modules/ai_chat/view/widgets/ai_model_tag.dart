// Aura attribution caption. While typing: "STREAMING · Aura"; once settled:
// "ANSWERED BY Aura". The raw model (Claude/Gemini/GPT) is a server-side detail
// the user never sees — Aura is the only brand surfaced [D-AI brand].

import 'package:flutter/material.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

/// The user-facing AI brand. Always Aura regardless of the routed model.
String aiModelBrand(String? model) => AuraBrand.name;

class AiModelTag extends StatelessWidget {
  final String? model;
  final bool streaming;

  const AiModelTag({super.key, required this.model, this.streaming = false});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final text = streaming
        ? 'Streaming · ${AuraBrand.name}'
        : 'Answered by ${AuraBrand.name}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        MonoLabel(text, color: c.grey500, size: 10, tracking: 0.14),
      ],
    );
  }
}
