import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/review_controller.dart';
import 'widgets/review_card.dart';
import 'widgets/review_card_content.dart';
import 'widgets/review_ghost_card.dart';
import 'widgets/review_progress_dots.dart';
import 'widgets/review_rating_row.dart';
import 'widgets/review_top_bar.dart';

class ReviewView extends GetView<ReviewController> {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Obx(
        () => RecallStateView(
          state: controller.viewState,
          loading: const Center(child: CircularProgressIndicator.adaptive()),
          errorMessage: controller.errorMessage,
          onRetry: controller.onAbandon,
          child: _ReviewContent(controller: controller),
        ),
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  final ReviewController controller;

  const _ReviewContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await controller.onAbandon();
      },
      child: Column(
        children: [
          Obx(() => ReviewTopBar(
                bucketName: controller.currentBucketName,
                position: controller.doneItems + 1,
                total: controller.totalItems,
                onClose: controller.onAbandon,
              )),
          Obx(() => ReviewProgressDots(
                total: controller.totalItems,
                current: controller.doneItems,
              )),
          Expanded(
            child: Obx(() => _buildCardStage(c, dark)),
          ),
          Obx(() => ReviewRatingRow(
                onRate: controller.onRate,
                intervalLabel: controller.intervalLabel,
                isLastCard: controller.isLastCard,
                activeGrade: null,
              )),
        ],
      ),
    );
  }

  Widget _buildCardStage(RecallColors c, bool dark) {
    final node = controller.currentNode;
    if (node == null) return const SizedBox.expand();

    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 22, right: 22),
      child: Stack(
        children: [
          const ReviewGhostCard(),
          _buildNextCard(c, dark),
          _buildFrontCard(c, dark),
        ],
      ),
    );
  }

  Widget _buildNextCard(RecallColors c, bool dark) {
    final nextIdx = controller.currentIndex.value + 1;
    if (nextIdx >= controller.items.length) return const SizedBox.shrink();

    final nextItem = controller.items[nextIdx];
    final nextNode = controller.nodes[nextItem.nodeId];
    if (nextNode == null) return const SizedBox.shrink();

    final nextBucket = controller.bucketNames[nextNode.bucketId] ?? '';

    return Positioned(
      left: 10,
      right: 10,
      top: 10,
      bottom: 64,
      child: Transform(
        transform: Matrix4.identity()..scale(0.97, 0.97),
        alignment: const Alignment(0, 0.7),
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: c.grey200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.45 : 0.07),
                offset: const Offset(0, 14),
                blurRadius: 30,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: ReviewCardContent(
            node: nextNode,
            bucketName: nextBucket,
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(RecallColors c, bool dark) {
    final item = controller.currentItem;
    final node = controller.currentNode;
    if (item == null || node == null) return const SizedBox.shrink();

    final bucketName = controller.currentBucketName;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 64,
      child: ReviewCard(
        onRate: controller.onRate,
        enabled: !controller.isAnimating.value && !controller.isCompleting.value,
        child: ReviewCardContent(
          node: node,
          bucketName: bucketName,
        ),
      ),
    );
  }
}
