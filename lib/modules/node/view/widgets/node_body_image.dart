import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/recall_skeleton.dart';

class NodeBodyImage extends StatelessWidget {
  final String? signedUrl;
  final String sizeLabel;

  const NodeBodyImage({super.key, this.signedUrl, this.sizeLabel = ''});

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
              if (signedUrl != null && signedUrl!.isNotEmpty)
                Image.network(
                  signedUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: RecallSkeleton(height: 200));
                  },
                  errorBuilder: (_, __, ___) => _placeholder(c),
                )
              else
                _placeholder(c),
              // IMG badge (bottom-left)
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
                    'IMG',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: c.canvas,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // Size badge (bottom-right)
              if (sizeLabel.isNotEmpty)
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

  Widget _placeholder(RecallColors c) {
    return Container(
      color: c.grey200,
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: c.grey400),
      ),
    );
  }
}
