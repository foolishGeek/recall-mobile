import 'package:flutter/material.dart' hide Stack;
import 'package:flutter/material.dart' as material show Stack;
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/mono_label.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/tap_to_refresh_nudge.dart';
import '../../../data/models/models.dart';
import '../controller/bucket_controller.dart';
import 'widgets/bucket_ai_chips.dart';
import 'widgets/bucket_config_card.dart';
import 'widgets/bucket_fab.dart';
import 'widgets/bucket_header.dart';
import 'widgets/bucket_mastery_card.dart';
import 'widgets/bucket_more_menu.dart';
import 'widgets/bucket_node_row.dart';
import 'widgets/bucket_top_bar.dart';

class BucketView extends GetView<BucketController> {
  const BucketView({super.key});

  @override
  Widget build(BuildContext context) {
    return RecallScaffold.bare(
      body: Obx(() {
        return RecallStateView(
          state: controller.viewState,
          errorMessage: controller.errorMessage,
          onRetry: controller.reload,
          child: material.Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TapToRefreshNudge(
                      onRefresh: controller.reload,
                    ),
                    BucketTopBar(
                      onBack: () => Get.back(),
                      onMore: () => _onMore(context),
                    ),
                    const SizedBox(height: 14),
                    Obx(() => BucketHeader(
                          name: controller.bucket.value?.name ?? '',
                          nodeCount: controller.nodeCount,
                          bucketId: controller.bucketId,
                        )),
                    const SizedBox(height: 18),
                    Obx(() {
                      if (!controller.hasNodes) return const SizedBox.shrink();
                      return BucketMasteryCard(
                        mastery: controller.mastery.value,
                        heat: controller.heatSummary,
                      );
                    }),
                    Obx(() {
                      if (!controller.hasNodes) return const SizedBox.shrink();
                      return const SizedBox(height: 12);
                    }),
                    Obx(() => BucketConfigCard(
                          coolingIndex: controller.coolingIndex,
                          frequencyIndex: controller.frequencyIndex,
                          capIndex: controller.dailyCapIndex,
                          disabled: controller.readOnly.value,
                          onCoolingChanged: controller.onCoolingChanged,
                          onFrequencyChanged: controller.onFrequencyChanged,
                          onCapChanged: controller.onDailyCapChanged,
                        )),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.gate.aiDisabled ||
                          controller.readOnly.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          BucketAiChips(
                            modelLabel: controller.aiModelLabel.value,
                            isSummarizing: controller.isSummarizing.value,
                            onSummarize: () => _onSummarize(context),
                            onAskAi: controller.onAskAiTap,
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    }),
                    Obx(() => _buildNodeSection(context)),
                  ],
                ),
              ),
              Obx(() {
                if (controller.readOnly.value) {
                  return _ReadOnlyBanner();
                }
                return Positioned(
                  right: 24,
                  bottom: 24,
                  child: BucketFab(onTap: controller.onAddNodeTap),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNodeSection(BuildContext context) {
    if (!controller.hasNodes) {
      return _EmptyNodesBody(onAddFirst: controller.onAddNodeTap);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel('Nodes · ${controller.nodeCount}'),
        const SizedBox(height: 10),
        ...controller.nodes.map((node) => BucketNodeRow(
              node: node,
              relativeTime: controller.relativeTime(node.lastReviewedAt),
              onTap: () => controller.onNodeTap(node),
            )),
      ],
    );
  }

  void _onMore(BuildContext context) {
    if (controller.readOnly.value) return;
    showBucketMoreMenu(
      context: context,
      currentName: controller.bucket.value?.name ?? '',
      onRename: controller.onRename,
      onDelete: controller.onDeleteConfirmed,
    );
  }

  void _onSummarize(BuildContext context) async {
    await controller.onSummarizeTap();
    final result = controller.summaryResult.value;
    final error = controller.summaryError.value;
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    if (result != null) {
      _showSummarySheet(context, result);
    }
  }

  void _showSummarySheet(BuildContext context, SummarizeResult result) {
    final c = RecallColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 16),
            Text(
              'Summary',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final bullet in result.summary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: c.grey600)),
                    Expanded(
                      child: Text(
                        bullet,
                        style:
                            GoogleFonts.inter(fontSize: 14, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            if (result.keyThemes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.keyThemes
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.grey300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: c.grey600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyNodesBody extends StatelessWidget {
  final VoidCallback onAddFirst;
  const _EmptyNodesBody({required this.onAddFirst});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.note_add_outlined, size: 40, color: c.grey400),
            const SizedBox(height: 14),
            Text(
              'No nodes yet',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first note, link, or PDF.',
              style: GoogleFonts.inter(fontSize: 14, color: c.grey500),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAddFirst,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '+ first node',
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
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: c.grey500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Read-only bucket. Upgrade to edit.',
                style: GoogleFonts.inter(fontSize: 13, color: c.grey600),
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed('/paywall'),
              child: Text(
                'Upgrade',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
