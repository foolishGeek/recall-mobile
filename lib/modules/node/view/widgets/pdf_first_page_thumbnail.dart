import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/recall_skeleton.dart';

/// Renders the real first page of a PDF (downloaded from its signed URL) into
/// a calm thumbnail. Results are cached in-memory by [cacheKey] so re-layouts
/// and stack peeks don't re-render the page.
class PdfFirstPageThumbnail extends StatefulWidget {
  final String? signedUrl;
  final String cacheKey;
  final BoxFit fit;

  const PdfFirstPageThumbnail({
    super.key,
    required this.signedUrl,
    required this.cacheKey,
    this.fit = BoxFit.cover,
  });

  static final Map<String, Uint8List> _cache = {};

  @override
  State<PdfFirstPageThumbnail> createState() => _PdfFirstPageThumbnailState();
}

class _PdfFirstPageThumbnailState extends State<PdfFirstPageThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PdfFirstPageThumbnail old) {
    super.didUpdateWidget(old);
    if (old.signedUrl != widget.signedUrl || old.cacheKey != widget.cacheKey) {
      _future = _load();
    }
  }

  Future<Uint8List?> _load() async {
    final cached = PdfFirstPageThumbnail._cache[widget.cacheKey];
    if (cached != null) return cached;

    final url = widget.signedUrl;
    if (url == null || url.isEmpty) return null;

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final document = await PdfDocument.openData(res.bodyBytes);
      final page = await document.getPage(1);
      // Cap the long edge so thumbnails stay light but crisp on retina.
      final scale = 900 / page.width;
      final image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      await document.close();

      final bytes = image?.bytes;
      if (bytes != null) PdfFirstPageThumbnail._cache[widget.cacheKey] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const RecallSkeleton(
            height: double.infinity,
            borderRadius: BorderRadius.zero,
          );
        }
        final bytes = snap.data;
        if (bytes == null) return _fallback(c);
        return Image.memory(bytes, fit: widget.fit);
      },
    );
  }

  Widget _fallback(RecallColors c) {
    return Container(
      color: c.card,
      child: Center(
        child: Icon(Icons.picture_as_pdf_outlined, size: 40, color: c.grey400),
      ),
    );
  }
}
