import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class NodeBodyPdf extends StatelessWidget {
  final String? signedUrl;
  final String sizeLabel;

  const NodeBodyPdf({
    super.key,
    this.signedUrl,
    required this.sizeLabel,
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
              // Simulated page lines.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(6, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      height: i == 0 ? 5 : 3,
                      width: i == 0 ? double.infinity * 0.8 : double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: i == 0 ? 200 : double.infinity,
                      ),
                      decoration: BoxDecoration(
                        color: i == 0 ? c.grey400 : c.grey200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
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
