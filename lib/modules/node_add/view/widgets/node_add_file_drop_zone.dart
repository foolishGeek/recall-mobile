import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class NodeAddFileDropZone extends StatelessWidget {
  final bool isPdf;
  final String? fileName;
  final int fileSizeBytes;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const NodeAddFileDropZone({
    super.key,
    required this.isPdf,
    this.fileName,
    this.fileSizeBytes = 0,
    this.isUploading = false,
    this.errorText,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final hasFile = fileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasFile ? c.card : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.grey300,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: hasFile ? _fileInfo(c) : _placeholder(c),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.inter(fontSize: 12, color: c.ink),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(RecallColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            size: 28,
            color: c.grey400,
          ),
          const SizedBox(height: 6),
          Text(
            isPdf ? 'Tap to upload PDF' : 'Tap to upload image',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileInfo(RecallColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            size: 24,
            color: c.ink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _sizeLabel(fileSizeBytes),
                  style: GoogleFonts.inter(fontSize: 11, color: c.grey500),
                ),
              ],
            ),
          ),
          if (isUploading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.grey400,
              ),
            )
          else if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close, size: 18, color: c.grey500),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
