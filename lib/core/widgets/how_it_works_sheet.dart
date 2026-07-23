// Recall · HowItWorksSheet. Opt-in explainer bottom sheet for calm, on-demand
// guidance. Matches Settings sheet rhythm (grip + Fraunces title + Inter body).
// Never auto-shows — only opened from a quiet "How it works" affordance.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/routes/app_routes.dart';
import '../theme/recall_colors.dart';
import '../utils/recall_haptics.dart';
import 'aura_mark.dart';

/// One short block inside [showHowItWorksSheet].
class HowItWorksSection {
  final String? heading;
  final String body;

  const HowItWorksSection({this.heading, required this.body});
}

Future<void> showHowItWorksSheet(
  BuildContext context, {
  required String title,
  required List<HowItWorksSection> sections,
  // Optional "Ask Aura" footer — turns every explainer into a 5-second lesson.
  // When [auraPrompt] is set, a quiet Aura row deep-links to the chat pre-seeded
  // with the question (bucket-scoped when [auraBucketIds] is provided).
  String? auraPrompt,
  List<String>? auraBucketIds,
}) {
  final c = RecallColors.of(context);
  RecallHaptics.selection();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Grip(),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          _Section(sections[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                if (auraPrompt != null) ...[
                  const SizedBox(height: 16),
                  _AskAuraRow(
                    prompt: auraPrompt,
                    bucketIds: auraBucketIds,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Quiet "Ask Aura" row for the explainer footer. Monochrome + AuraMark; no
/// model name. Closes the sheet, then opens Aura chat pre-seeded with [prompt].
class _AskAuraRow extends StatelessWidget {
  final String prompt;
  final List<String>? bucketIds;
  final VoidCallback onTap;

  const _AskAuraRow({
    required this.prompt,
    required this.bucketIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RecallHaptics.selection();
        onTap();
        Get.toNamed(Routes.aiChat, arguments: {
          if (bucketIds != null) 'bucket_ids': bucketIds,
          'seed_prompt': prompt,
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.canvas,
          border: Border.all(color: c.grey200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const AuraMark(size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ask Aura to explain in your words',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: c.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.grey500),
          ],
        ),
      ),
    );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: c.grey400,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final HowItWorksSection section;
  const _Section(this.section);

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.heading != null) ...[
          Text(
            section.heading!,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          section.body,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: c.grey600,
          ),
        ),
      ],
    );
  }
}
