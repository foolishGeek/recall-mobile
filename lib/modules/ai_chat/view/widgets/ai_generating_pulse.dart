// While the answer types out: a pulsing mono "GENERATING…" caption next to a
// Stop chip that halts the simulated typing [S20 §9].

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';

class AiGeneratingPulse extends StatefulWidget {
  final VoidCallback onStop;

  const AiGeneratingPulse({super.key, required this.onStop});

  @override
  State<AiGeneratingPulse> createState() => _AiGeneratingPulseState();
}

class _AiGeneratingPulseState extends State<AiGeneratingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Row(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
          child: MonoLabel('Generating\u2026',
              color: c.grey500, size: 9.5, tracking: 0.2),
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onStop,
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.grey200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stop_rounded, size: 12, color: c.grey600),
                const SizedBox(width: 5),
                Text('Stop',
                    style: t.bodySm.copyWith(color: c.grey600, height: 1.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
