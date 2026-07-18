import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../controller/quiz_config_controller.dart';
import 'quiz_config_chip.dart';

class QuizConfigModeTop extends StatelessWidget {
  final QuizConfigController controller;

  const QuizConfigModeTop({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isFreehand) return _PromptBox(controller: controller);
    if (controller.isByBucket) return _BucketPicker(controller: controller);
    return _NodePicker(controller: controller);
  }
}

class _PromptBox extends StatelessWidget {
  final QuizConfigController controller;

  const _PromptBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MonoLabel('Topic', size: 9),
              Obx(() => MonoLabel(
                    '${controller.promptText.value.length} / 280',
                    size: 9,
                  )),
            ],
          ),
          TextField(
            controller: controller.promptController,
            maxLength: 280,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: 'Eigenvectors - but the intuition, not the math.',
            ),
            style: t.serifItalic.copyWith(color: c.ink, fontSize: 22),
          ),
          Divider(color: c.grey200),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GhostPrompt(
                label: 'try "Krebs, harder"',
                onTap: () => controller.applyGhostPrompt('Krebs, harder'),
              ),
              _GhostPrompt(
                label: '"German dates"',
                onTap: () => controller.applyGhostPrompt('German dates'),
              ),
              _GhostPrompt(
                label: '"git rebase"',
                onTap: () => controller.applyGhostPrompt('git rebase'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Optional scope for free-hand quizzes: which buckets Aura should mine for
/// collective topics. Leaving everything unselected means "all my notes".
class QuizFreehandScope extends StatelessWidget {
  final QuizConfigController controller;

  const QuizFreehandScope({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoLabel('Draw from', size: 9),
          const SizedBox(height: 6),
          Obx(() => Text(
                controller.selectedBucketIds.isEmpty
                    ? 'All your notes — pick buckets to narrow the topics.'
                    : '${controller.selectedBucketIds.length} bucket(s) selected.',
                style: t.bodyXs.copyWith(color: c.grey500, height: 1.35),
              )),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final bucket in controller.buckets)
                    QuizConfigChip(
                      label: bucket.name,
                      meta: controller.nodes
                          .where((n) => n.bucketId == bucket.id)
                          .length
                          .toString(),
                      selected:
                          controller.selectedBucketIds.contains(bucket.id),
                      onTap: () => controller.toggleBucket(bucket.id),
                    ),
                ],
              )),
        ],
      ),
    );
  }
}

class _BucketPicker extends StatelessWidget {
  final QuizConfigController controller;

  const _BucketPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final bucket in controller.buckets)
            QuizConfigChip(
              label: bucket.name,
              meta: controller.nodes
                  .where((n) => n.bucketId == bucket.id)
                  .length
                  .toString(),
              selected: controller.selectedBucketIds.contains(bucket.id),
              onTap: () => controller.toggleBucket(bucket.id),
            ),
        ],
      ),
    );
  }
}

class _NodePicker extends StatelessWidget {
  final QuizConfigController controller;

  const _NodePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final node in controller.nodes)
            QuizConfigChip(
              label: node.title.isEmpty ? 'Untitled note' : node.title,
              selected: controller.selectedNodeIds.contains(node.id),
              onTap: () => controller.toggleNode(node.id),
            ),
        ],
      ),
    );
  }
}

class _GhostPrompt extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostPrompt({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: c.grey200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: t.bodyXs.copyWith(color: c.grey500)),
      ),
    );
  }
}
