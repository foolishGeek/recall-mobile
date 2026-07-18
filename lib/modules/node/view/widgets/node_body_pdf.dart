import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import 'pdf_first_page_thumbnail.dart';

class NodeBodyPdf extends StatelessWidget {
  final String? signedUrl;
  final String sizeLabel;

  /// Asset id used to key the rendered first-page thumbnail cache.
  final String cacheKey;

  const NodeBodyPdf({
    super.key,
    this.signedUrl,
    required this.sizeLabel,
    this.cacheKey = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.grey200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: c.card),
              // Real first-page render (skeleton while loading, glyph on error).
              PdfFirstPageThumbnail(
                signedUrl: signedUrl,
                cacheKey: cacheKey.isEmpty ? (signedUrl ?? '') : cacheKey,
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'PDF',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: c.canvas,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.grey200),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    sizeLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: c.grey500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
