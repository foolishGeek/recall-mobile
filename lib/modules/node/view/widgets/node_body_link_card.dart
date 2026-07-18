import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/link_preview.dart';

class NodeBodyLinkCard extends StatelessWidget {
  final LinkPreview preview;
  final VoidCallback? onTap;

  const NodeBodyLinkCard({
    super.key,
    required this.preview,
    this.onTap,
  });

  String get _subtitle {
    final parts = <String>[];
    if (preview.readTimeSec != null && preview.readTimeSec! > 0) {
      final min = (preview.readTimeSec! / 60).ceil();
      parts.add('$min min read');
    }
    parts.add('open in browser');
    return parts.join(' · ');
  }

  /// Host of the link, e.g. `arxiv.org` — used as the brand line + favicon
  /// source when the preview didn't return a site name/image.
  static String? hostOf(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    final host = uri?.host;
    if (host == null || host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// Prefer the real site name; otherwise fall back to the domain so every
  /// card reads as a rich preview, never a bare URL.
  String? get _brandLine {
    final s = preview.siteName;
    if (s != null && s.trim().isNotEmpty) return s;
    return hostOf(preview.canonicalUrl);
  }

  /// When the preview has no title, show the domain as the primary line so the
  /// card still has a confident headline.
  String? get _titleLine {
    final t = preview.title;
    if (t != null && t.trim().isNotEmpty) return t;
    return hostOf(preview.canonicalUrl);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final brand = _brandLine;
    final title = _titleLine;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Thumb(preview: preview, colors: c),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand != null && brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: c.grey500,
                        letterSpacing: 0.16 * 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (title != null && title.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: c.grey500,
                      height: 1.45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 64×64 thumbnail: link preview image when available, else an on-brand
/// diagonal hatch with a link glyph (matches the mockup).
class _Thumb extends StatelessWidget {
  final LinkPreview preview;
  final RecallColors colors;

  const _Thumb({required this.preview, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: preview.imageUrl != null && preview.imageUrl!.isNotEmpty
            ? Image.network(
                preview.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _favicon(),
              )
            : _favicon(),
      ),
    );
  }

  /// Falls back to the site favicon (on a calm hatch) so a card without an
  /// OG image still reads as a real link preview, not a blank tile.
  Widget _favicon() {
    final host = NodeBodyLinkCard.hostOf(preview.canonicalUrl);
    if (host == null) return _hatch();
    return Stack(
      fit: StackFit.expand,
      children: [
        _hatch(showGlyph: false),
        Center(
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=$host&sz=128',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.link_rounded, size: 22, color: colors.grey500),
          ),
        ),
      ],
    );
  }

  Widget _hatch({bool showGlyph = true}) {
    return CustomPaint(
      painter: _HatchPainter(
        stripeA: colors.grey300,
        stripeB: colors.grey200,
      ),
      child: showGlyph
          ? Center(
              child: Icon(Icons.link_rounded, size: 22, color: colors.grey500),
            )
          : null,
    );
  }
}

class _HatchPainter extends CustomPainter {
  final Color stripeA;
  final Color stripeB;

  _HatchPainter({required this.stripeA, required this.stripeB});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = stripeA;
    canvas.drawRect(Offset.zero & size, bg);

    final stripe = Paint()
      ..color = stripeB
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    const step = 12.0;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) =>
      old.stripeA != stripeA || old.stripeB != stripeB;
}
