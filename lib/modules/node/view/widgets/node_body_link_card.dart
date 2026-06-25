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

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
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
                  if (preview.siteName != null &&
                      preview.siteName!.isNotEmpty)
                    Text(
                      preview.siteName!.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: c.grey500,
                        letterSpacing: 0.16 * 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (preview.title != null && preview.title!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      preview.title!,
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
        child: preview.imageUrl != null
            ? Image.network(
                preview.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _hatch(),
              )
            : _hatch(),
      ),
    );
  }

  Widget _hatch() {
    return CustomPaint(
      painter: _HatchPainter(
        stripeA: colors.grey300,
        stripeB: colors.grey200,
      ),
      child: Center(
        child: Icon(Icons.link_rounded, size: 22, color: colors.grey500),
      ),
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
