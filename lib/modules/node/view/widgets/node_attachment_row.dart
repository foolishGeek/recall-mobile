import 'package:flutter/material.dart';

import '../../../../data/models/node_asset.dart';
import 'node_body_image.dart';
import 'node_body_pdf.dart';

/// Horizontal, scrollable row of all attachments (PDFs + images, in order).
/// Each card shows a realistic preview — the image itself or the PDF's first
/// page. Tapping opens the fullscreen viewer at that index.
class NodeAttachmentRow extends StatelessWidget {
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final void Function(int index) onTapIndex;

  const NodeAttachmentRow({
    super.key,
    required this.assets,
    required this.signedUrls,
    required this.onTapIndex,
  });

  static const double _cardWidth = 150;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _cardWidth * 4 / 3,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: assets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final asset = assets[i];
          return GestureDetector(
            onTap: () => onTapIndex(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(width: _cardWidth, child: _preview(asset)),
          );
        },
      ),
    );
  }

  Widget _preview(NodeAsset asset) {
    final signedUrl = signedUrls[asset.id];
    final sizeLabel = _fileSizeLabel(asset.fileSizeBytes);
    if (asset.mimeType.contains('pdf')) {
      final pdfLabel =
          asset.pageCount != null ? '$sizeLabel · ${asset.pageCount}p' : sizeLabel;
      return NodeBodyPdf(
        signedUrl: signedUrl,
        sizeLabel: pdfLabel,
        cacheKey: asset.id,
      );
    }
    return NodeBodyImage(signedUrl: signedUrl, sizeLabel: sizeLabel);
  }

  String _fileSizeLabel(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
