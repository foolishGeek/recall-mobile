// Empty-thread state: a quiet question and suggested prompts from the
// controller (bucket-aware when a scope is set). Static copy is only the
// final offline fallback.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

const kFallbackSuggestions = <String>[];

class AiSuggestedPrompts extends StatelessWidget {
  final ValueChanged<String> onTap;
  final List<String> suggestions;
  final String? header;

  const AiSuggestedPrompts({
    super.key,
    required this.onTap,
    this.suggestions = const [],
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final prompts = suggestions.isNotEmpty ? suggestions : kFallbackSuggestions;
    final label = header ?? 'What do you want to remember?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        MonoLabel(label, color: c.grey500, size: 11, tracking: 0.16),
        const SizedBox(height: 16),
        for (final prompt in prompts) ...[
          _PromptChip(text: prompt, onTap: () => onTap(prompt)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.grey200),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 13, color: c.grey500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.fraunces(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
