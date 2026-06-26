// AuraRatingSheet — a soft, dismissible nudge shown after a few answers asking
// how Aura's doing. 1–5 calm dots + an optional one-line suggestion. Frequency
// capping lives in the controller; this widget is pure UI. Low-cortisol: easy
// to dismiss, no guilt copy, never blocks the thread.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/aura_mark.dart';

class AuraRatingSheet extends StatefulWidget {
  final Future<void> Function(int rating, String text) onSubmit;

  const AuraRatingSheet({super.key, required this.onSubmit});

  static Future<void> show({
    required Future<void> Function(int rating, String text) onSubmit,
  }) {
    return Get.bottomSheet(
      AuraRatingSheet(onSubmit: onSubmit),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  @override
  State<AuraRatingSheet> createState() => _AuraRatingSheetState();
}

class _AuraRatingSheetState extends State<AuraRatingSheet> {
  final _input = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _sending) return;
    setState(() => _sending = true);
    RecallHaptics.medium();
    await widget.onSubmit(_rating, _input.text);
    if (Get.isBottomSheetOpen ?? false) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    const AuraMark(size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'How\u2019s ${AuraBrand.name} doing?',
                        style: GoogleFonts.fraunces(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Get.back(),
                      child: Icon(Icons.close_rounded, size: 18, color: c.grey400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'A quick read helps ${AuraBrand.name} tune to you. Totally '
                  'optional.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.grey600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 1; i <= 5; i++) _dot(c, i),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: c.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.grey200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 14, color: c.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Anything Aura should do differently? (optional)',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 13, color: c.grey400),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _rating == 0 ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.ink,
                      foregroundColor: c.inkOnInk,
                      disabledBackgroundColor: c.grey200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.grey500),
                          )
                        : Text(
                            'Send',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.inkOnInk,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(RecallColors c, int value) {
    final active = value <= _rating;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RecallHaptics.selection();
        setState(() => _rating = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? c.ink : c.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: active ? c.ink : c.grey200),
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? c.inkOnInk : c.grey500,
          ),
        ),
      ),
    );
  }
}
