import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/note_links.dart';
import '../../../../data/models/models.dart' hide Stack;
import '../../../node/view/widgets/node_body_image.dart';
import '../../../node/view/widgets/node_body_link_card.dart';
import '../../../node/view/widgets/node_body_pdf.dart';
import '../../../node/view/widgets/node_body_youtube.dart';
import 'review_card_legacy_previews.dart';

/// Review swipe card — must NEVER paint an empty body when the note has any
/// title, markdown, extracted text, links, or attachments.
class ReviewCardContent extends StatelessWidget {
  final Node node;
  final String bucketName;
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final List<LinkPreview> contentLinks;
  final void Function(int index)? onOpenAttachment;

  const ReviewCardContent({
    super.key,
    required this.node,
    required this.bucketName,
    this.assets = const [],
    this.signedUrls = const {},
    this.contentLinks = const [],
    this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final title = node.title.trim().isEmpty ? 'Untitled note' : node.title.trim();
    final body = _bodyText();
    final links = <LinkPreview>[];
    final videos = <LinkPreview>[];
    void classify(LinkPreview? lp) {
      if (lp == null) return;
      if (lp.videoId != null && lp.videoId!.isNotEmpty) {
        videos.add(lp);
      } else {
        links.add(lp);
      }
    }

    classify(node.linkPreview);
    for (final lp in contentLinks) {
      classify(lp);
    }

    final hasMedia = assets.isNotEmpty || links.isNotEmpty || videos.isNotEmpty;
    final hasBody = body.isNotEmpty;

    // Single scroll — no Expanded flex games that can collapse to zero height.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${bucketName.toUpperCase()} \u00B7 ${node.type.wire.toUpperCase()}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 10 * 0.2,
            color: c.grey500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          // Inter — never rely solely on runtime-fetched Fraunces for swipe cards.
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.3,
            color: c.ink,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: (hasBody || hasMedia)
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasBody) _ReviewMarkdown(text: body, colors: c),
                      if (hasBody && hasMedia) const SizedBox(height: 16),
                      if (assets.isNotEmpty) ...[
                        _AttachmentTile(
                          assets: assets,
                          signedUrls: signedUrls,
                          onOpenAttachment: onOpenAttachment,
                        ),
                        if (links.isNotEmpty || videos.isNotEmpty)
                          const SizedBox(height: 14),
                      ],
                      for (var i = 0; i < links.length; i++) ...[
                        NodeBodyLinkCard(
                          preview: links[i],
                          onTap: () => _openUrl(links[i].canonicalUrl),
                        ),
                        if (i != links.length - 1) const SizedBox(height: 10),
                      ],
                      if (links.isNotEmpty && videos.isNotEmpty)
                        const SizedBox(height: 14),
                      for (var i = 0; i < videos.length; i++) ...[
                        _VideoBlock(colors: c, preview: videos[i]),
                        if (i != videos.length - 1) const SizedBox(height: 12),
                      ],
                      // Legacy-only media when composed body was empty.
                      if (!hasBody && !hasMedia) const SizedBox.shrink(),
                    ],
                  ),
                )
              : _legacyOrEmpty(context, c),
        ),
        _Footer(node: node, colors: c),
      ],
    );
  }

  /// Prefer prose (URLs stripped), then raw markdown, then extracted_text.
  String _bodyText() {
    final prose = stripStandaloneUrls(node.markdown).trim();
    if (prose.isNotEmpty) return prose;
    final rawMd = (node.markdown ?? '').trim();
    if (rawMd.isNotEmpty) return rawMd;
    final proseEt = stripStandaloneUrls(node.extractedText).trim();
    if (proseEt.isNotEmpty) return proseEt;
    return (node.extractedText ?? '').trim();
  }

  Widget _legacyOrEmpty(BuildContext context, RecallColors c) {
    switch (node.type) {
      case NodeType.link:
        return ReviewLegacyLinkPreview(node: node);
      case NodeType.youtube:
        return ReviewLegacyYoutubePreview(node: node);
      case NodeType.pdf:
      case NodeType.image:
        if (assets.isNotEmpty) {
          return _AttachmentTile(
            assets: assets,
            signedUrls: signedUrls,
            onOpenAttachment: onOpenAttachment,
          );
        }
        break;
      default:
        break;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'No details on this note yet.\nOpen it from the bucket to add content.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: c.grey600,
          ),
        ),
      ),
    );
  }
}

/// Markdown rendered with Inter only — avoids blank glyphs if Fraunces hasn't
/// finished downloading on-device.
class _ReviewMarkdown extends StatelessWidget {
  final String text;
  final RecallColors colors;

  const _ReviewMarkdown({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.inter(
      fontSize: 16,
      height: 1.55,
      color: colors.ink,
    );
    return MarkdownBody(
      data: text,
      selectable: false,
      shrinkWrap: true,
      softLineBreak: true,
      onTapLink: (label, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: body,
        h1: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.ink,
          height: 1.3,
        ),
        h2: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: colors.ink,
          height: 1.3,
        ),
        h3: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.ink,
          height: 1.35,
        ),
        listBullet: body,
        listIndent: 20,
        blockSpacing: 12,
        strong: body.copyWith(fontWeight: FontWeight.w700),
        em: body.copyWith(fontStyle: FontStyle.italic),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: colors.ink,
          backgroundColor: colors.grey200,
        ),
        a: body.copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final RecallColors colors;
  final LinkPreview preview;

  const _VideoBlock({required this.colors, required this.preview});

  @override
  Widget build(BuildContext context) {
    final videoId = preview.videoId;
    if (videoId == null || videoId.isEmpty) {
      return NodeBodyLinkCard(
        preview: preview,
        onTap: () => _openUrl(preview.canonicalUrl),
      );
    }
    final dur = preview.durationSec;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NodeBodyYoutube(
          videoId: videoId,
          durationLabel: dur == null ? '' : _formatDuration(dur),
          onTap: () => _openUrl(
            preview.canonicalUrl ?? 'https://youtube.com/watch?v=$videoId',
          ),
        ),
        if (preview.title != null || preview.siteName != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (preview.siteName != null) preview.siteName!,
              if (preview.title != null) preview.title!,
            ].join(' · '),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.ink,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final void Function(int index)? onOpenAttachment;

  const _AttachmentTile({
    required this.assets,
    required this.signedUrls,
    this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final first = assets.first;
    final isPdf = first.mimeType.contains('pdf');
    final sizeLabel = _fileSizeLabel(first.fileSizeBytes);
    final Widget preview = isPdf
        ? NodeBodyPdf(
            signedUrl: signedUrls[first.id],
            sizeLabel: first.pageCount != null
                ? '$sizeLabel \u00B7 ${first.pageCount}p'
                : sizeLabel,
            cacheKey: first.id,
          )
        : NodeBodyImage(
            signedUrl: signedUrls[first.id],
            sizeLabel: sizeLabel,
          );

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenAttachment == null ? null : () => onOpenAttachment!(0),
        child: preview,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Node node;
  final RecallColors colors;

  const _Footer({required this.node, required this.colors});

  @override
  Widget build(BuildContext context) {
    final dueText = _formatDue(node.dueAt);
    final priorityLabel = _priorityLabel(node.priority);
    final priorityColor = _priorityColor(node.priority);

    return Container(
      padding: const EdgeInsets.only(top: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.grey200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (priorityLabel != null)
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: priorityColor,
                border: Border.all(color: const Color(0xFF111111), width: 1.5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                priorityLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 9.5 * 0.08,
                  color: const Color(0xFF111111),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          Text(
            dueText,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: colors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

void _openUrl(String? url) {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _fileSizeLabel(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatDue(DateTime? dueAt) {
  if (dueAt == null) return '';
  final now = DateTime.now();
  final diff = dueAt.difference(now);
  if (diff.isNegative) {
    final days = diff.inDays.abs();
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due yesterday';
    return 'Due $days days ago';
  }
  final days = diff.inDays;
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'In $days days';
}

String? _priorityLabel(int priority) {
  if (priority >= 4) return 'HIGH';
  if (priority == 3) return 'MED';
  if (priority <= 2) return 'LOW';
  return null;
}

Color _priorityColor(int priority) {
  if (priority >= 4) return const Color(0xFFE5484D);
  if (priority == 3) return const Color(0xFFF5A623);
  return const Color(0xFF46A758);
}
