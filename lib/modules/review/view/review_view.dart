import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../data/models/models.dart' hide Stack;
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

class _ReviewContent extends StatefulWidget {
  final ReviewController controller;

  const _ReviewContent({required this.controller});

  @override
  State<_ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends State<_ReviewContent> {
  // One GlobalKey per stack item so every card gets its own fresh State
  // (no animation/offset carryover between cards) while still letting the
  // rating buttons drive the current card's throw animation.
  final Map<String, GlobalKey<ReviewCardState>> _cardKeys = {};

  ReviewController get controller => widget.controller;

  GlobalKey<ReviewCardState> _keyFor(String itemId) =>
      _cardKeys.putIfAbsent(itemId, () => GlobalKey<ReviewCardState>());

  void _onRateViaThrow(ReviewGrade grade) {
    if (!controller.canRate) return;
    final item = controller.currentItem;
    final state = item != null ? _cardKeys[item.id]?.currentState : null;
    if (state != null) {
      state.triggerThrow(grade);
    } else {
      controller.onThrowStarted();
      controller.onRate(grade);
    }
  }

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
                onRate: _onRateViaThrow,
                intervalLabel: controller.intervalLabel,
                isLastCard: controller.isLastCard,
                activeGrade: controller.dragGrade.value,
                enabled:
                    controller.canRate && controller.currentNode != null,
              )),
        ],
      ),
    );
  }

  Widget _buildCardStage(RecallColors c, bool dark) {
    final item = controller.currentItem;
    if (item == null) {
      return const SizedBox.expand();
    }

    final node = controller.nodes[item.nodeId];
    if (node == null) {
      return _MissingNodePlaceholder(
        onSkip: controller.skipMissingNode,
        onClose: controller.onAbandon,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 22, right: 22),
      child: Stack(
        children: [
          const ReviewGhostCard(),
          _buildNextCard(c, dark),
          _buildFrontCard(c, dark, item, node),
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

  Widget _buildFrontCard(
    RecallColors c,
    bool dark,
    StackItem item,
    Node node,
  ) {
    final bucketName = controller.currentBucketName;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 64,
      child: ReviewCard(
        key: _keyFor(item.id),
        onRate: controller.onRate,
        onThrowStarted: controller.onThrowStarted,
        onDragGradeChanged: controller.onDragGradeChanged,
        enabled: controller.canRate,
        child: ReviewCardContent(
          node: node,
          bucketName: bucketName,
        ),
      ),
    );
  }
}

class _MissingNodePlaceholder extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onClose;

  const _MissingNodePlaceholder({
    required this.onSkip,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes_outlined, size: 40, color: c.grey500),
            const SizedBox(height: 16),
            Text(
              'This card couldn\'t be loaded',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skip to continue your session, or close and try again later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: c.grey500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: c.grey500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onSkip,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.inkOnInk,
                  ),
                  child: Text(
                    'Skip card',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
