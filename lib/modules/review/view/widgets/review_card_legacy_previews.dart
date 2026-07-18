import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/models.dart' hide Stack;

/// Legacy full-bleed link preview for old `NodeType.link` rows.
class ReviewLegacyLinkPreview extends StatelessWidget {
  final Node node;

  const ReviewLegacyLinkPreview({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
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
                        lp?.siteName ?? _domain(node.url),
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

  static String _domain(String? url) {
    if (url == null) return '';
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }
}

/// Legacy YouTube thumb for old `NodeType.youtube` rows.
class ReviewLegacyYoutubePreview extends StatelessWidget {
  final Node node;

  const ReviewLegacyYoutubePreview({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
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
            style: GoogleFonts.inter(
                fontSize: 11.5, color: c.grey500, height: 1.45),
          ),
        ],
      ],
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
