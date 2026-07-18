import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/node_asset.dart';
import '../../../node/view/widgets/pdf_first_page_thumbnail.dart';
import '../../controller/picked_file.dart';

/// Unified attachments editor: shows existing + newly-picked PDFs and images as
/// a compact wrap of removable thumbnails, plus an "Add" tile that offers PDF
/// or image (multi-select). Works for any note type — a note can hold mixed
/// files. Fully tokenized, no color.
class NodeAddAttachments extends StatelessWidget {
  final List<NodeAsset> existingAssets;
  final Map<String, String> existingSignedUrls;
  final List<PickedFile> pickedFiles;
  final ValueChanged<NodeAsset> onRemoveExisting;
  final ValueChanged<PickedFile> onRemovePicked;
  final VoidCallback onAddPdf;
  final VoidCallback onAddImage;

  const NodeAddAttachments({
    super.key,
    required this.existingAssets,
    required this.existingSignedUrls,
    required this.pickedFiles,
    required this.onRemoveExisting,
    required this.onRemovePicked,
    required this.onAddPdf,
    required this.onAddImage,
  });

  static const double _tile = 76;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final a in existingAssets)
          _Thumb(
            colors: c,
            isPdf: a.mimeType.contains('pdf'),
            imageProvider: !a.mimeType.contains('pdf') &&
                    (existingSignedUrls[a.id]?.isNotEmpty ?? false)
                ? NetworkImage(existingSignedUrls[a.id]!)
                : null,
            pdfThumb: a.mimeType.contains('pdf')
                ? PdfFirstPageThumbnail(
                    signedUrl: existingSignedUrls[a.id],
                    cacheKey: a.id,
                  )
                : null,
            onRemove: () => onRemoveExisting(a),
          ),
        for (final f in pickedFiles)
          _Thumb(
            colors: c,
            isPdf: f.isPdf,
            imageProvider: !f.isPdf ? MemoryImage(f.bytes) : null,
            pdfThumb: null,
            onRemove: () => onRemovePicked(f),
          ),
        _AddTile(colors: c, onAddPdf: onAddPdf, onAddImage: onAddImage),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final RecallColors colors;
  final bool isPdf;
  final ImageProvider? imageProvider;
  final Widget? pdfThumb;
  final VoidCallback onRemove;

  const _Thumb({
    required this.colors,
    required this.isPdf,
    required this.imageProvider,
    required this.pdfThumb,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return SizedBox(
      width: NodeAddAttachments._tile,
      height: NodeAddAttachments._tile,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: NodeAddAttachments._tile,
              height: NodeAddAttachments._tile,
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.grey200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _content(c),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.grey200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.close, size: 13, color: c.grey600),
              ),
            ),
          ),
          if (isPdf)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PDF',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: c.canvas,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content(RecallColors c) {
    if (imageProvider != null) {
      return Image(image: imageProvider!, fit: BoxFit.cover);
    }
    if (pdfThumb != null) return pdfThumb!;
    return Center(
      child: Icon(Icons.picture_as_pdf_outlined, size: 26, color: c.grey400),
    );
  }
}

class _AddTile extends StatelessWidget {
  final RecallColors colors;
  final VoidCallback onAddPdf;
  final VoidCallback onAddImage;

  const _AddTile({
    required this.colors,
    required this.onAddPdf,
    required this.onAddImage,
  });

  void _showMenu(BuildContext context) {
    final c = colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _row(ctx, Icons.picture_as_pdf_outlined, 'Add PDF', () {
                Navigator.pop(ctx);
                onAddPdf();
              }),
              _row(ctx, Icons.image_outlined, 'Add image', () {
                Navigator.pop(ctx);
                onAddImage();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
      BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    final c = colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.ink),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: () => _showMenu(context),
      behavior: HitTestBehavior.opaque,
      child: DottedBorderBox(
        size: NodeAddAttachments._tile,
        color: c.grey300,
        radius: 14,
        child: Icon(Icons.add, size: 24, color: c.grey500),
      ),
    );
  }
}

/// Simple dashed-border square matching the drop-zone language.
class DottedBorderBox extends StatelessWidget {
  final double size;
  final Color color;
  final double radius;
  final Widget child;

  const DottedBorderBox({
    super.key,
    required this.size,
    required this.color,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = (dist + dash).clamp(0, metric.length) - dist;
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}
