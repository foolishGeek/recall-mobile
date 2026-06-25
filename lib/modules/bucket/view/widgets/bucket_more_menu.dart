import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';

Future<void> showBucketMoreMenu({
  required BuildContext context,
  required String currentName,
  required ValueChanged<String> onRename,
  required VoidCallback onDelete,
}) async {
  final c = RecallColors.of(context);
  await showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MenuRow(
              icon: Icons.edit_outlined,
              label: 'Rename bucket',
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(
                  context: context,
                  currentName: currentName,
                  onRename: onRename,
                );
              },
            ),
            const SizedBox(height: 4),
            _MenuRow(
              icon: Icons.delete_outline,
              label: 'Delete bucket',
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(
                  context: context,
                  bucketName: currentName,
                  onDelete: onDelete,
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final color = destructive ? c.chipRed : c.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRenameDialog({
  required BuildContext context,
  required String currentName,
  required ValueChanged<String> onRename,
}) {
  final c = RecallColors.of(context);
  final ctrl = TextEditingController(text: currentName);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Rename bucket',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: c.ink,
        ),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 15, color: c.ink),
        decoration: InputDecoration(
          hintText: 'Bucket name',
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
            final name = ctrl.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(ctx);
              onRename(name);
            }
          },
          child: Text('Save',
              style: GoogleFonts.inter(
                  color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

void _showDeleteConfirm({
  required BuildContext context,
  required String bucketName,
  required VoidCallback onDelete,
}) {
  final c = RecallColors.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delete "$bucketName"?',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All nodes in this bucket will be removed. This can\'t be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: c.grey600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  RecallHaptics.heavy();
                  Navigator.pop(ctx);
                  onDelete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.chipRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete bucket',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: c.grey600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
