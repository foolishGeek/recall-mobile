import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/link_preview.dart';

class NodeAddYoutubeBody extends StatelessWidget {
  final TextEditingController urlCtrl;
  final LinkPreview? preview;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  const NodeAddYoutubeBody({
    super.key,
    required this.urlCtrl,
    this.preview,
    this.isLoading = false,
    this.errorText,
    required this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: urlCtrl,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: c.ink),
          decoration: InputDecoration(
            hintText: 'Paste a YouTube URL…',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: c.grey400),
            prefixIcon:
                Icon(Icons.play_circle_outline, size: 18, color: c.grey500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.grey200, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.grey200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.ink, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.inter(fontSize: 12, color: c.ink),
          ),
        ],
        if (isLoading) ...[
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.grey400,
              ),
            ),
          ),
        ],
        if (preview != null && !isLoading) ...[
          const SizedBox(height: 16),
          _YouTubeCard(preview: preview!, colors: c),
        ],
      ],
    );
  }
}

class _YouTubeCard extends StatelessWidget {
  final LinkPreview preview;
  final RecallColors colors;

  const _YouTubeCard({required this.preview, required this.colors});

  @override
  Widget build(BuildContext context) {
    final videoId = preview.videoId ?? '';
    final thumbUrl = videoId.isNotEmpty
        ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.grey200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbUrl != null
                    ? Image.network(thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: colors.grey200,
                            ))
                    : Container(color: colors.grey200),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _durationLabel(preview.durationSec),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.title != null)
                  Text(
                    preview.title!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (preview.siteName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview.siteName!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.grey500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int? sec) {
    if (sec == null) return '▶';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '▶ $m:${s.toString().padLeft(2, '0')}';
  }
}
