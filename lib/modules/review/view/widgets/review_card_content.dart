import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/models.dart' hide Stack;
import '../../../node/view/widgets/node_body_image.dart';
import '../../../node/view/widgets/node_body_markdown.dart';
import '../../../node/view/widgets/node_body_pdf.dart';

class ReviewCardContent extends StatelessWidget {
  final Node node;
  final String bucketName;

  /// Attachments for this node (pdf/image) and their signed URLs, keyed by
  /// asset id. Empty when the node has no files or they failed to load.
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;

  /// Opens the fullscreen attachment viewer at [index]. Null disables tapping.
  final void Function(int index)? onOpenAttachment;

  const ReviewCardContent({
    super.key,
    required this.node,
    required this.bucketName,
    this.assets = const [],
    this.signedUrls = const {},
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
    final typeLabel = node.type.wire;

    return Text(
      '${bucketName.toUpperCase()} \u00B7 ${typeLabel.toUpperCase()}',
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
    switch (node.type) {
      case NodeType.link:
        return _buildLinkPreview(context, c);
      case NodeType.youtube:
        return _buildYouTubePreview(context, c);
      case NodeType.pdf:
      case NodeType.image:
        return _buildAttachmentPreview(context, c);
      default:
        return _buildMarkdown(context, c);
    }
  }

  Widget _buildAttachmentPreview(BuildContext context, RecallColors c) {
    if (assets.isEmpty) {
      // Attachments unavailable (offline / signing failed) — fall back to any
      // text, else a quiet placeholder so the card is never blank.
      final text = node.markdown ?? node.extractedText ?? '';
      if (text.isNotEmpty) return _buildMarkdown(context, c);
      return _buildAttachmentPlaceholder(c);
    }

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

  Widget _buildAttachmentPlaceholder(RecallColors c) {
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

  Widget _buildMarkdown(BuildContext context, RecallColors c) {
    final text = node.markdown ?? node.extractedText ?? '';

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: NodeBodyMarkdown(
        markdown: text,
        selectable: false,
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context, RecallColors c) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lp = node.linkPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.grey200, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [const Color(0xFF2A2A30), const Color(0xFF16161B)]
                            : [const Color(0xFFF0EEEA), const Color(0xFFE7E5E1)],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.link, size: 36, color: c.grey500),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.grey200, width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lp?.siteName ?? _extractDomain(node.url),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          letterSpacing: 9.5 * 0.16,
                          color: c.grey500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lp?.title ?? node.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lp?.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          lp!.description!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: c.grey500,
                            height: 1.45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePreview(BuildContext context, RecallColors c) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lp = node.linkPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xFF2A2A30), const Color(0xFF16161B)]
                    : [const Color(0xFF3a3935), const Color(0xFF1F1E1B)],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? c.ink : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(13, 18),
                      painter: _PlayTrianglePainter(
                        color: dark ? c.canvas : const Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
                if (lp?.durationSec != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(lp!.durationSec!),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'YOUTUBE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        letterSpacing: 9.5 * 0.08,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        if (lp?.title != null)
          Text(
            lp!.title!,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.ink,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (lp?.siteName != null) ...[
          const SizedBox(height: 3),
          Text(
            lp!.siteName!,
            style: GoogleFonts.inter(fontSize: 11.5, color: c.grey500, height: 1.45),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(RecallColors c) {
    final dueText = _formatDue(node.dueAt);
    final priorityLabel = _priorityLabel(node.priority);
    final priorityColor = _priorityColor(node.priority);

    return Column(
      children: [
        Container(
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
                    border: Border.all(
                        color: const Color(0xFF111111), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF111111),
                        offset: Offset(2, 2),
                      ),
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
                  color: c.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _extractDomain(String? url) {
    if (url == null) return '';
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
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
    } else {
      final days = diff.inDays;
      if (days == 0) return 'Due today';
      if (days == 1) return 'Due tomorrow';
      return 'In $days days';
    }
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

class _PlayTrianglePainter extends CustomPainter {
  final Color color;
  _PlayTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(3, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(3, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayTrianglePainter old) => old.color != color;
}
