import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/recall_button.dart';
import '../../controller/quiz_config_controller.dart';

class QuizConfigFooter extends StatelessWidget {
  final QuizConfigController controller;

  const QuizConfigFooter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        decoration: BoxDecoration(
          color: c.canvas.withValues(alpha: 0.94),
          border: Border(top: BorderSide(color: c.grey200)),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: controller.generating.value
                    ? 'Generating...'
                    : 'Generate quiz',
                onPressed: controller.canGenerate ? controller.generate : null,
              ),
              const SizedBox(height: 8),
              Text(
                controller.footerHint,
                style: t.monoCaption.copyWith(color: c.grey500),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class QuizConfigToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? caption;

  const QuizConfigToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: t.label.copyWith(
              color: c.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (caption != null) ...[
          Text(caption!, style: t.monoCaption.copyWith(color: c.grey500)),
          const SizedBox(width: 10),
        ],
        RecallToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
