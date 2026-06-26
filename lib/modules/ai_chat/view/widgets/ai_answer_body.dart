// The editorial answer body: a Fraunces lead paragraph followed by Inter body
// paragraphs, with inline `[1]` citation markers rendered in mono. Pure render
// of the `ai-forge` `answer` string — paragraph splitting only, no logic.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';

final _paragraphSplit = RegExp(r'\n\s*\n|\n');
final _citationToken = RegExp(r'\[\d+\]');

class AiAnswerBody extends StatelessWidget {
  final String text;

  const AiAnswerBody({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    final paragraphs = text
        .split(_paragraphSplit)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    final lead = GoogleFonts.fraunces(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: -0.1,
      color: c.ink,
    );
    final body = t.body.copyWith(color: c.ink, height: 1.6, fontSize: 14.5);
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: c.grey500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: i == 0 ? lead : body,
              children: _spans(paragraphs[i], i == 0 ? lead : body, mono),
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _spans(String paragraph, TextStyle base, TextStyle mono) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _citationToken.allMatches(paragraph)) {
      if (match.start > last) {
        spans.add(TextSpan(text: paragraph.substring(last, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: mono));
      last = match.end;
    }
    if (last < paragraph.length) {
      spans.add(TextSpan(text: paragraph.substring(last)));
    }
    return spans;
  }
}
