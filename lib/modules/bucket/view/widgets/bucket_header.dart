import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/mono_label.dart';

class BucketHeader extends StatelessWidget {
  final String name;
  final String? description;
  final int nodeCount;
  final String bucketId;
  final bool readOnly;
  final ValueChanged<String>? onEditDescription;

  const BucketHeader({
    super.key,
    required this.name,
    this.description,
    required this.nodeCount,
    required this.bucketId,
    this.readOnly = false,
    this.onEditDescription,
  });

  bool get _hasDescription => (description?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel('Bucket · $nodeCount ${nodeCount == 1 ? 'note' : 'notes'}',
            size: 10.5, tracking: 0.2),
        const SizedBox(height: 6),
        Hero(
          tag: 'bucket_name_$bucketId',
          child: Material(
            color: Colors.transparent,
            child: Text(
              name,
              style: GoogleFonts.fraunces(
                fontSize: 44,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.88,
                color: c.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildDescription(context, c),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, RecallColors c) {
    if (_hasDescription) {
      return GestureDetector(
        onTap: readOnly ? null : () => _openEditor(context),
        behavior: HitTestBehavior.opaque,
        child: Text(
          description!.trim(),
          style: GoogleFonts.fraunces(
            fontSize: 13.5,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            height: 1.35,
            color: c.grey600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (readOnly) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _openEditor(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 13, color: c.grey500),
          const SizedBox(width: 5),
          Text(
            'Add description',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: c.grey500,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context) {
    RecallHaptics.selection();
    _showEditDescriptionDialog(
      context: context,
      current: description ?? '',
      onSave: (value) => onEditDescription?.call(value),
    );
  }
}

void _showEditDescriptionDialog({
  required BuildContext context,
  required String current,
  required ValueChanged<String> onSave,
}) {
  final c = RecallColors.of(context);
  final ctrl = TextEditingController(text: current);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        current.trim().isEmpty ? 'Add description' : 'Edit description',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: c.ink,
        ),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        minLines: 2,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        style: GoogleFonts.inter(fontSize: 15, color: c.ink),
        decoration: InputDecoration(
          hintText: 'What is this bucket about?',
          hintStyle: GoogleFonts.inter(fontSize: 15, color: c.grey400),
          filled: true,
          fillColor: c.canvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.ink, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: c.grey600, fontSize: 14)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onSave(ctrl.text.trim());
          },
          child: Text('Save',
              style: GoogleFonts.inter(
                  color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
