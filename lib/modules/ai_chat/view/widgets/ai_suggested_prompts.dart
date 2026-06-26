// Empty-thread state: a quiet question and two static suggested prompts. Static
// copy only — no backend [D-UI-4].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/mono_label.dart';

const _suggestions = <String>[
  'What did I learn yesterday?',
  'Summarize my Spanish notes',
];

class AiSuggestedPrompts extends StatelessWidget {
  final ValueChanged<String> onTap;

  const AiSuggestedPrompts({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        MonoLabel('What do you want to remember?',
            color: c.grey500, size: 11, tracking: 0.16),
        const SizedBox(height: 16),
        for (final prompt in _suggestions) ...[
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
