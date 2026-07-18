import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/note_links.dart';
import '../../../../data/models/models.dart' hide Stack;
import '../../../node/view/widgets/node_body_image.dart';
import '../../../node/view/widgets/node_body_link_card.dart';
import '../../../node/view/widgets/node_body_markdown.dart';
import '../../../node/view/widgets/node_body_pdf.dart';
import '../../../node/view/widgets/node_body_youtube.dart';
import 'review_card_legacy_previews.dart';

/// Review card body — same content model as node detail: prose (URLs stripped),
/// attachments, then LINKED / WATCH cards. Legacy single-type nodes fall back
/// to the older preview layouts when the composed body would be empty.
class ReviewCardContent extends StatelessWidget {
  final Node node;
  final String bucketName;

  /// Attachments for this node (pdf/image) and their signed URLs, keyed by
  /// asset id. Empty when the node has no files or they failed to load.
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;

  /// Link / video previews seeded from markdown (and enriched async).
  final List<LinkPreview> contentLinks;

  /// Opens the fullscreen attachment viewer at [index]. Null disables tapping.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(c),
        const SizedBox(height: 12),
        _buildTitle(c),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(context, c)),
        _buildFooter(c),
      ],
    );
  }

  Widget _buildHeader(RecallColors c) {
    return Text(
      '${bucketName.toUpperCase()} \u00B7 ${node.type.wire.toUpperCase()}',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 10 * 0.2,
        color: c.grey500,
      ),
    );
  }

  Widget _buildTitle(RecallColors c) {
    return Text(
      node.title,
      style: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: -0.015 * 26,
        color: c.ink,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBody(BuildContext context, RecallColors c) {
    final prose = _proseText();
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

    if (prose.isNotEmpty || assets.isNotEmpty || links.isNotEmpty || videos.isNotEmpty) {
      return _ComposedBody(
        prose: prose,
        assets: assets,
        signedUrls: signedUrls,
        links: links,
        videos: videos,
        onOpenAttachment: onOpenAttachment,
      );
    }

    switch (node.type) {
      case NodeType.link:
        return ReviewLegacyLinkPreview(node: node);
      case NodeType.youtube:
        return ReviewLegacyYoutubePreview(node: node);
      case NodeType.pdf:
      case NodeType.image:
        return _LegacyAttachmentBody(
          node: node,
          assets: assets,
          signedUrls: signedUrls,
          onOpenAttachment: onOpenAttachment,
        );
      default:
        return Center(
          child: Text(
            'No content on this card',
            style: GoogleFonts.inter(fontSize: 13, color: c.grey500),
          ),
        );
    }
  }

  String _proseText() {
    final fromMd = stripStandaloneUrls(node.markdown);
    if (fromMd.isNotEmpty) return fromMd;
    return stripStandaloneUrls(node.extractedText);
  }

  Widget _buildFooter(RecallColors c) {
    final dueText = _formatDue(node.dueAt);
    final priorityLabel = _priorityLabel(node.priority);
    final priorityColor = _priorityColor(node.priority);

    return Container(
      padding: const EdgeInsets.only(top: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.grey200, width: 1)),
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
            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: c.grey500),
          ),
        ],
      ),
    );
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
}

class _ComposedBody extends StatelessWidget {
  final String prose;
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final List<LinkPreview> links;
  final List<LinkPreview> videos;
  final void Function(int index)? onOpenAttachment;

  const _ComposedBody({
    required this.prose,
    required this.assets,
    required this.signedUrls,
    required this.links,
    required this.videos,
    this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prose.isNotEmpty) ...[
            NodeBodyMarkdown(markdown: prose, selectable: false),
            if (assets.isNotEmpty || links.isNotEmpty || videos.isNotEmpty)
              const SizedBox(height: 16),
          ],
          if (assets.isNotEmpty) ...[
            _AttachmentTile(
              assets: assets,
              signedUrls: signedUrls,
              onOpenAttachment: onOpenAttachment,
            ),
            if (links.isNotEmpty || videos.isNotEmpty) const SizedBox(height: 14),
          ],
          for (var i = 0; i < links.length; i++) ...[
            NodeBodyLinkCard(
              preview: links[i],
              onTap: () => _openUrl(links[i].canonicalUrl),
            ),
            if (i != links.length - 1) const SizedBox(height: 10),
          ],
          if (links.isNotEmpty && videos.isNotEmpty) const SizedBox(height: 14),
          for (var i = 0; i < videos.length; i++) ...[
            _ReviewVideoCard(colors: c, preview: videos[i]),
            if (i != videos.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ReviewVideoCard extends StatelessWidget {
  final RecallColors colors;
  final LinkPreview preview;

  const _ReviewVideoCard({required this.colors, required this.preview});

  @override
  Widget build(BuildContext context) {
    final videoId = preview.videoId;
    if (videoId == null || videoId.isEmpty) {
      return NodeBodyLinkCard(
        preview: preview,
        onTap: () => _openUrl(preview.canonicalUrl),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NodeBodyYoutube(
          videoId: videoId,
          durationLabel: preview.durationSec != null
              ? _formatDuration(preview.durationSec!)
              : '',
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

class _LegacyAttachmentBody extends StatelessWidget {
  final Node node;
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final void Function(int index)? onOpenAttachment;

  const _LegacyAttachmentBody({
    required this.node,
    required this.assets,
    required this.signedUrls,
    this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    if (assets.isEmpty) {
      final text = node.markdown ?? node.extractedText ?? '';
      if (text.isNotEmpty) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: NodeBodyMarkdown(markdown: text, selectable: false),
        );
      }
      final isPdf = node.type == NodeType.pdf;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 36,
              color: c.grey400,
            ),
            const SizedBox(height: 10),
            Text(
              isPdf ? 'PDF attachment' : 'Image attachment',
              style: GoogleFonts.inter(fontSize: 13, color: c.grey500),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: _AttachmentTile(
        assets: assets,
        signedUrls: signedUrls,
        onOpenAttachment: onOpenAttachment,
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
