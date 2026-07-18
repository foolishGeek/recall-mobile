import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';

class SaveBar extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const SaveBar({
    super.key,
    this.isEditMode = false,
    this.isSaving = false,
    this.canSave = true,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0.6, 1.0],
          colors: [c.canvas, c.canvas.withValues(alpha: 0)],
        ),
      ),
      child: Row(
        children: [
          if (isEditMode && onDelete != null) ...[
            _SecondaryButton(
              icon: Icons.delete_outline,
              colors: c,
              onTap: onDelete!,
            ),
            const SizedBox(width: 8),
          ] else ...[
            _SecondaryButton(
              icon: Icons.auto_awesome,
              colors: c,
              onTap: () {},
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: canSave
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: Theme.of(context).brightness == Brightness.light
                                ? 0.18
                                : 0.4,
                          ),
                          offset: Theme.of(context).brightness == Brightness.light
                              ? const Offset(0, 8)
                              : const Offset(0, 10),
                          blurRadius:
                              Theme.of(context).brightness == Brightness.light
                                  ? 22
                                  : 24,
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: canSave && !isSaving ? onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSave ? c.ink : c.grey400,
                  foregroundColor: c.inkOnInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.inkOnInk,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEditMode ? 'Save changes' : 'Save note',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.inkOnInk,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.check, size: 15, color: c.inkOnInk),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final RecallColors colors;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 54,
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.grey400, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: colors.grey600),
      ),
    );
  }
}
