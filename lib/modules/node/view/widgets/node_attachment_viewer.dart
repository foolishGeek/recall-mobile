import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../../../core/widgets/recall_skeleton.dart';
import '../../../../data/models/node_asset.dart';

/// Low-cortisol scrim: the dark-canvas tone, not a harsh pure black.
const Color _kScrim = Color(0xFF0E0E11);
const Color _kOnScrim = Color(0xFFF5F4F1);

/// Fullscreen, swipeable viewer for a group of attachments (all images or all
/// PDFs). Images pinch-zoom via [InteractiveViewer]; PDFs use pdfx's
/// [PdfViewPinch]. Signed URLs are passed in (already signed on load), so this
/// needs no repository access.
class NodeAttachmentViewer extends StatefulWidget {
  final List<NodeAsset> assets;
  final Map<String, String> signedUrls;
  final int initialIndex;

  const NodeAttachmentViewer({
    super.key,
    required this.assets,
    required this.signedUrls,
    this.initialIndex = 0,
  });

  static Future<void> open(
    BuildContext context, {
    required List<NodeAsset> assets,
    required Map<String, String> signedUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: _kScrim,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => NodeAttachmentViewer(
          assets: assets,
          signedUrls: signedUrls,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<NodeAttachmentViewer> createState() => _NodeAttachmentViewerState();
}

class _NodeAttachmentViewerState extends State<NodeAttachmentViewer> {
  late final PageController _pageCtrl;
  late int _index;
  final Map<String, PdfControllerPinch> _pdfControllers = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _pdfControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Uint8List> _fetchBytes(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load file (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  PdfControllerPinch _pdfControllerFor(NodeAsset asset, String url) {
    return _pdfControllers.putIfAbsent(
      asset.id,
      () => PdfControllerPinch(document: PdfDocument.openData(_fetchBytes(url))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.assets.length;
    return Scaffold(
      backgroundColor: _kScrim,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _page(widget.assets[i]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: _kOnScrim, size: 24),
                  ),
                  const Spacer(),
                  if (total > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${_index + 1} / $total',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: _kOnScrim,
                          letterSpacing: 0.16 * 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _page(NodeAsset asset) {
    final url = widget.signedUrls[asset.id];
    if (url == null || url.isEmpty) return _error();

    if (asset.mimeType.contains('pdf')) {
      return PdfViewPinch(
        controller: _pdfControllerFor(asset, url),
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: RecallSkeleton(width: 220, height: 300),
          ),
          pageLoaderBuilder: (_) => const Center(
            child: RecallSkeleton(width: 220, height: 300),
          ),
          errorBuilder: (_, __) => _error(),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: RecallSkeleton(width: 220, height: 300));
          },
          errorBuilder: (_, __, ___) => _error(),
        ),
      ),
    );
  }

  Widget _error() {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: _kOnScrim, size: 48),
    );
  }
}
