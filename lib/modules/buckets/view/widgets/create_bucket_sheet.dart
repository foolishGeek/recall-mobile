import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_shape.dart';
import '../../../../core/utils/recall_haptics.dart';

/// Lightweight create/edit-bucket flow: a polished bottom sheet collecting a
/// name and an optional description. On submit it hands both back to the caller.
/// Reused for editing by prefilling values and swapping the copy + CTA.
class CreateBucketSheet extends StatefulWidget {
  final void Function(String name, String? description) onCreate;
  final String initialName;
  final String? initialDescription;
  final String title;
  final String subtitle;
  final String ctaLabel;

  const CreateBucketSheet({
    super.key,
    required this.onCreate,
    this.initialName = '',
    this.initialDescription,
    this.title = 'New bucket',
    this.subtitle = 'Name it and add a short description.',
    this.ctaLabel = 'Create bucket',
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(String name, String? description) onCreate,
    String initialName = '',
    String? initialDescription,
    String title = 'New bucket',
    String subtitle = 'Name it and add a short description.',
    String ctaLabel = 'Create bucket',
  }) {
    final c = RecallColors.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateBucketSheet(
        onCreate: onCreate,
        initialName: initialName,
        initialDescription: initialDescription,
        title: title,
        subtitle: subtitle,
        ctaLabel: ctaLabel,
      ),
    );
  }

  @override
  State<CreateBucketSheet> createState() => _CreateBucketSheetState();
}

class _CreateBucketSheetState extends State<CreateBucketSheet> {
  late final _nameCtrl = TextEditingController(text: widget.initialName);
  late final _descCtrl =
      TextEditingController(text: widget.initialDescription ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final desc = _descCtrl.text.trim();
    RecallHaptics.light();
    Navigator.pop(context);
    widget.onCreate(name, desc.isEmpty ? null : desc);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.grey400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: SvgPicture.asset(
                  'assets/illustrations/onboarding-buckets.svg',
                  height: 56,
                  colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  widget.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(fontSize: 13, color: c.grey500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _Label(text: 'NAME', c: c),
              const SizedBox(height: 6),
              _Field(
                controller: _nameCtrl,
                hint: 'e.g. Maths',
                autofocus: true,
                c: c,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              _Label(text: 'DESCRIPTION', c: c),
              const SizedBox(height: 6),
              _Field(
                controller: _descCtrl,
                hint: 'What lives in this bucket? (optional)',
                minLines: 2,
                maxLines: 4,
                c: c,
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameCtrl,
                builder: (context, value, _) {
                  final enabled = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: enabled ? _submit : null,
                    child: Opacity(
                      opacity: enabled ? 1.0 : 0.4,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.ink,
                          borderRadius:
                              BorderRadius.circular(RecallShape.radiusMd + 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.ctaLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.inkOnInk,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final RecallColors c;
  const _Label({required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: c.grey500,
        letterSpacing: 0.16 * 10,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final RecallColors c;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    required this.c,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(fontSize: 15, color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}
