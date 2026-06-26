// QuizFeedbackSheet — opt-in, skippable post-quiz feedback that calibrates Aura
// for this user (helpfulness + difficulty + optional note). Low-cortisol: no
// guilt, easy to skip, reuses the results-screen tone.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/aura_mark.dart';

class QuizFeedbackSheet extends StatefulWidget {
  final Future<void> Function(bool helpful, int difficulty, String text)
      onSubmit;
  final VoidCallback onSkip;

  const QuizFeedbackSheet({
    super.key,
    required this.onSubmit,
    required this.onSkip,
  });

  static Future<void> show({
    required Future<void> Function(bool helpful, int difficulty, String text)
        onSubmit,
    required VoidCallback onSkip,
  }) {
    return Get.bottomSheet(
      QuizFeedbackSheet(onSubmit: onSubmit, onSkip: onSkip),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<QuizFeedbackSheet> createState() => _QuizFeedbackSheetState();
}

class _QuizFeedbackSheetState extends State<QuizFeedbackSheet> {
  final _input = TextEditingController();
  bool? _helpful;
  int _difficulty = 0; // -1 too easy, 0 right, +1 too hard
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_helpful == null || _sending) return;
    setState(() => _sending = true);
    RecallHaptics.medium();
    await widget.onSubmit(_helpful!, _difficulty, _input.text);
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
                        'How was this quiz?',
                        style: GoogleFonts.fraunces(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.onSkip();
                        Get.back();
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _label(c, 'Helpful?'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _choice(c, 'Yes', _helpful == true,
                        () => setState(() => _helpful = true)),
                    const SizedBox(width: 8),
                    _choice(c, 'Not really', _helpful == false,
                        () => setState(() => _helpful = false)),
                  ],
                ),
                const SizedBox(height: 16),
                _label(c, 'Difficulty'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _choice(c, 'Too easy', _difficulty == -1,
                        () => setState(() => _difficulty = -1)),
                    const SizedBox(width: 8),
                    _choice(c, 'Just right', _difficulty == 0,
                        () => setState(() => _difficulty = 0)),
                    const SizedBox(width: 8),
                    _choice(c, 'Too hard', _difficulty == 1,
                        () => setState(() => _difficulty = 1)),
                  ],
                ),
                const SizedBox(height: 16),
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
                      hintText: 'Anything ${AuraBrand.name} should tweak? '
                          '(optional)',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 13, color: c.grey400),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _helpful == null ? null : _submit,
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
                            'Send feedback',
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

  Widget _label(RecallColors c, String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: c.grey500,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _choice(RecallColors c, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          RecallHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.ink : c.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? c.ink : c.grey200),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? c.inkOnInk : c.grey600,
            ),
          ),
        ),
      ),
    );
  }
}
