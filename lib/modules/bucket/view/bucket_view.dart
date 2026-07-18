import 'package:flutter/material.dart' hide Stack;
import 'package:flutter/material.dart' as material show Stack;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/utils/recall_share.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/tap_to_refresh_nudge.dart';
import '../../../data/models/models.dart';
import '../controller/bucket_controller.dart';
import 'widgets/bucket_ai_chips.dart';
import 'widgets/bucket_config_card.dart';
import 'widgets/bucket_custom_cooling_dialog.dart';
import 'widgets/bucket_header.dart';
import 'widgets/bucket_mastery_card.dart';
import 'widgets/bucket_more_menu.dart';
import 'widgets/bucket_node_row.dart';
import 'widgets/bucket_top_bar.dart';
import 'widgets/summary_share_card.dart';
import 'widgets/summary_sheet_actions.dart';

class BucketView extends GetView<BucketController> {
  const BucketView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return RecallScaffold.bare(
      body: Obx(() {
        return RecallStateView(
          state: controller.viewState,
          errorMessage: controller.errorMessage,
          onRetry: controller.reload,
          child: Column(
            children: [
              Expanded(
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
                                description:
                                    controller.bucket.value?.description,
                                nodeCount: controller.nodeCount,
                                bucketId: controller.bucketId,
                                readOnly: controller.readOnly.value,
                                onEditDescription:
                                    controller.onEditDescription,
                              )),
                          const SizedBox(height: 18),
                          Obx(() {
                            if (!controller.hasNodes) {
                              return const SizedBox.shrink();
                            }
                            return BucketMasteryCard(
                              mastery: controller.mastery.value,
                              dueCount: controller.dueCount,
                              overdueCount: controller.overdueCount,
                            );
                          }),
                          Obx(() {
                            if (!controller.hasNodes) {
                              return const SizedBox.shrink();
                            }
                            return const SizedBox(height: 12);
                          }),
                          Obx(() => BucketConfigCard(
                                coolingIndex: controller.coolingIndex,
                                customDays: controller.customCoolingDays,
                                frequencyIndex: controller.frequencyIndex,
                                disabled: controller.readOnly.value,
                                onCoolingChanged: (i) =>
                                    _onCoolingChanged(context, i),
                                onFrequencyChanged:
                                    controller.onFrequencyChanged,
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
                                  isSummarizing:
                                      controller.isSummarizing.value,
                                  disabled: !controller.hasNodes,
                                  onSummarize: () => _onSummarize(context),
                                  onAskAi: controller.onAskAiTap,
                                ),
                                const SizedBox(height: 18),
                              ],
                            );
                          }),
                          Obx(() {
                            if (!controller.hasNodes) {
                              return const SizedBox.shrink();
                            }
                            return const _CenterDivider();
                          }),
                          Obx(() => _buildNodeSection(context)),
                        ],
                      ),
                    ),
                    Obx(() {
                      if (controller.readOnly.value) {
                        return _ReadOnlyBanner();
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              // Bottom-pinned Save bar (visible only when config has changes)
              Obx(() {
                if (!controller.hasPendingChanges.value) {
                  return const SizedBox.shrink();
                }
                return _ConfigSaveBar(
                  isSaving: controller.isSavingConfig.value,
                  onSave: controller.onSaveConfig,
                  onDiscard: controller.onDiscardConfig,
                  colors: c,
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNodeSection(BuildContext context) {
    final c = RecallColors.of(context);
    if (!controller.hasNodes) {
      return _EmptyNodesBody(onAddFirst: controller.onAddNodeTap);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Notes',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${controller.nodeCount})',
              style: GoogleFonts.fraunces(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: c.grey500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.cycleSortMode,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  controller.sortLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: c.grey500,
                    letterSpacing: 0.16 * 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...controller.nodes.map((node) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: BucketNodeRow(
                node: node,
                dueLabel: controller.nodeDueLabel(node.dueAt),
                onTap: () => controller.onNodeTap(node),
              ),
            )),
      ],
    );
  }

  Future<void> _onCoolingChanged(BuildContext context, int index) async {
    // Custom slot (last index) prompts for a day count; presets apply directly.
    if (index == BucketConfigCard.coolingLabels.length - 1) {
      final days = await showCustomCoolingDialog(
        context: context,
        initialDays: controller.customCoolingDays ?? 14,
      );
      if (days != null) {
        controller.onCustomCoolingChanged(days);
      }
      return;
    }
    controller.onCoolingChanged(index);
  }

  void _onMore(BuildContext context) {
    if (controller.readOnly.value) return;
    showBucketMoreMenu(
      context: context,
      currentName: controller.bucket.value?.name ?? '',
      currentDescription: controller.bucket.value?.description,
      onEditBucket: controller.onEditBucket,
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
        builder: (sheetCtx, scroll) {
          SummaryShareCard buildShareCard() => SummaryShareCard(
                bucketName: controller.bucket.value?.name ?? '',
                result: result,
                colors: c,
              );
          return ListView(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Summary',
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ),
                  SummarySheetAction(
                    tooltip: 'Share',
                    icon: ShareMarkIcon(color: c.ink, size: 15),
                    onTap: () async {
                      RecallHaptics.selection();
                      await RecallShare.shareWidget(
                        card: buildShareCard(),
                        context: sheetCtx,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  SummarySheetAction(
                    tooltip: 'Save',
                    icon: SaveMarkIcon(color: c.ink, size: 15),
                    onTap: () async {
                      RecallHaptics.selection();
                      final ok = await RecallShare.saveWidgetToGallery(
                        card: buildShareCard(),
                        context: sheetCtx,
                      );
                      if (!sheetCtx.mounted) return;
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Saved to Photos'
                              : "Couldn't save image — try again."),
                        ),
                      );
                    },
                  ),
                ],
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
          );
        },
      ),
    );
  }
}

class _CenterDivider extends StatelessWidget {
  const _CenterDivider();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          width: 40,
          height: 1,
          color: c.grey200,
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
            SvgPicture.asset(
              'assets/illustrations/empty-seed-in-bowl.svg',
              height: 96,
              colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
            ),
            const SizedBox(height: 18),
            Text(
              'No notes yet',
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
                  '+ first note',
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

class _ConfigSaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final RecallColors colors;

  const _ConfigSaveBar({
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.grey200, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiet status: line-art glyph + mono label, no pulsing/blinking.
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 14, color: colors.grey500),
              const SizedBox(width: 8),
              Text(
                'UNSAVED CHANGES',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: colors.grey500,
                  letterSpacing: 0.16 * 9.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Discard button
              Expanded(
                child: GestureDetector(
                  onTap: isSaving ? null : onDiscard,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border.all(color: colors.grey200),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.undo_rounded, size: 16, color: colors.grey600),
                        const SizedBox(width: 6),
                        Text(
                          'Discard',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Save button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: isSaving ? null : onSave,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSaving ? colors.grey400 : colors.ink,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.inkOnInk,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18, color: colors.inkOnInk),
                              const SizedBox(width: 6),
                              Text(
                                'Save changes',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkOnInk,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
