import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/recall_colors.dart';

/// Renders node markdown content using flutter_markdown with Recall tokens.
/// Editorial Fraunces serif 17 body, Fraunces headings, JetBrains Mono code.
class NodeBodyMarkdown extends StatelessWidget {
  final String markdown;
  final bool selectable;

  const NodeBodyMarkdown({
    super.key,
    required this.markdown,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return MarkdownBody(
      data: markdown,
      selectable: selectable,
      shrinkWrap: true,
      onTapLink: (text, href, title) {
        if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      },
      styleSheet: _buildStyleSheet(c, context),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(RecallColors c, BuildContext context) {
    // Editorial body: Fraunces serif 17 / line-height 1.6 (matches mockup prose).
    final bodyStyle = GoogleFonts.fraunces(
      fontSize: 17,
      color: c.ink,
      height: 1.6,
      letterSpacing: -0.05,
    );
    // Lists use a slightly smaller Inter for scannable item rows.
    final listStyle = GoogleFonts.inter(
      fontSize: 14,
      color: c.ink,
      height: 1.85,
    );
    final codeStyle = GoogleFonts.jetBrainsMono(
      fontSize: 13,
      color: c.ink,
      height: 1.5,
    );

    return MarkdownStyleSheet(
      p: bodyStyle,
      h1: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: c.ink,
        height: 1.35,
      ),
      h2: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: c.ink,
        height: 1.4,
      ),
      h3: GoogleFonts.fraunces(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: c.ink,
        height: 1.4,
      ),
      h4: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.ink,
        height: 1.4,
      ),
      h5: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.ink,
        height: 1.4,
      ),
      h6: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.grey600,
        height: 1.4,
      ),
      em: bodyStyle.copyWith(fontStyle: FontStyle.italic),
      strong: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      blockquote: GoogleFonts.fraunces(
        fontSize: 15,
        height: 1.5,
        fontStyle: FontStyle.italic,
        color: c.grey600,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.grey500, width: 2)),
        color: c.card,
        borderRadius: BorderRadius.circular(6),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      code: codeStyle.copyWith(backgroundColor: c.grey200),
      codeblockDecoration: BoxDecoration(
        color: c.grey200,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      listBullet: listStyle.copyWith(color: c.grey500),
      listIndent: 20,
      blockSpacing: 14,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.grey200, width: 1)),
      ),
      a: bodyStyle.copyWith(
        color: c.ink,
        decoration: TextDecoration.underline,
      ),
      tableHead: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      tableBody: bodyStyle,
      tableBorder: TableBorder.all(color: c.grey200, width: 1),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}
