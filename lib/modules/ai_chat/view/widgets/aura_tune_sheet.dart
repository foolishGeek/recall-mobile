// Tune Aura — transparency + control over per-user personalization [D-AI-8].
// Shows what Aura has learned (style directives), lets the user add a plain
// suggestion (instantly acknowledged), and reset everything. Low-cortisol:
// soft surface, no destructive-red, dismissible.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/brand/aura_brand.dart';
import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../core/widgets/aura_mark.dart';
import '../../controller/ai_chat_controller.dart';

class AuraTuneSheet extends StatefulWidget {
  final AiChatController controller;

  const AuraTuneSheet({super.key, required this.controller});

  static Future<void> show(AiChatController controller) {
    return Get.bottomSheet(
      AuraTuneSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<AuraTuneSheet> createState() => _AuraTuneSheetState();
}

class _AuraTuneSheetState extends State<AuraTuneSheet> {
  final _input = TextEditingController();
  String? _ack;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadAuraPrefs();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    RecallHaptics.selection();
    final ack = await widget.controller.sendSuggestion(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _ack = ack ?? 'Saved — it\'ll apply on your next question.';
      _input.clear();
    });
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
                    Text(
                      'Tune ${AuraBrand.name}',
                      style: GoogleFonts.fraunces(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell ${AuraBrand.name} how you like answers — it learns just '
                  'for you, never for anyone else.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.grey600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _learned(c),
                const SizedBox(height: 16),
                _composer(c),
                if (_ack != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: c.grey600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ack!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: c.grey600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _learned(RecallColors c) {
    return Obx(() {
      final dirs = widget.controller.auraDirectives;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.cardSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'What ${AuraBrand.name}\u2019s learned',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: c.grey500,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                if (dirs.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await widget.controller.clearAuraPrefs();
                      if (mounted) setState(() => _ack = null);
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (dirs.isEmpty)
              Text(
                'Nothing yet — your suggestions will show up here.',
                style: GoogleFonts.inter(fontSize: 13, color: c.grey500),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in dirs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: c.grey500,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              d,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: c.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _composer(RecallColors c) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: c.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.grey200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.inter(fontSize: 14, color: c.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'e.g. keep answers shorter, add examples',
                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: c.grey400),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _sending ? c.grey200 : c.ink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _sending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.grey500),
                  )
                : Icon(Icons.arrow_upward_rounded, size: 20, color: c.inkOnInk),
          ),
        ),
      ],
    );
  }
}
