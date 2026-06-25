import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/link_preview.dart';

class NodeAddLinkBody extends StatelessWidget {
  final TextEditingController urlCtrl;
  final LinkPreview? preview;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClearPreview;

  const NodeAddLinkBody({
    super.key,
    required this.urlCtrl,
    this.preview,
    this.isLoading = false,
    this.errorText,
    required this.onSubmitted,
    this.onChanged,
    this.onClearPreview,
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
          style: GoogleFonts.inter(
            fontSize: 14,
            color: c.ink,
          ),
          decoration: InputDecoration(
            hintText: 'Paste a URL…',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: c.grey400),
            prefixIcon: Icon(Icons.link, size: 18, color: c.grey500),
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
          const SizedBox(height: 12),
          _LinkPreviewCard(
            preview: preview!,
            colors: c,
            onClear: onClearPreview,
          ),
        ],
      ],
    );
  }
}

class _LinkPreviewCard extends StatelessWidget {
  final LinkPreview preview;
  final RecallColors colors;
  final VoidCallback? onClear;

  const _LinkPreviewCard({
    required this.preview,
    required this.colors,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.grey200, width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Thumbnail / placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colors.grey200,
            ),
            child: preview.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      preview.imageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.link,
                        color: colors.grey400,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(Icons.link, color: colors.grey400, size: 24),
          ),
          const SizedBox(width: 10),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview.siteName != null)
                  Text(
                    preview.siteName!.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: colors.grey500,
                      letterSpacing: 0.16 * 9.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (preview.title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      preview.title!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (preview.canonicalUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      preview.canonicalUrl!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: colors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Clear button
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 16, color: colors.grey500),
              ),
            ),
        ],
      ),
    );
  }
}
