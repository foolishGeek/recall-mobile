import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/theme/recall_motion.dart';
import '../../../core/widgets/recall_skeleton.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../empty/view/widgets/empty_today_body.dart';
import '../controller/today_controller.dart';
import 'widgets/today_heat_ring.dart';
import 'widgets/today_peeking_stack.dart';
import 'widgets/today_relearn_card.dart';
import 'widgets/today_stacks_meter.dart';
import 'widgets/today_start_cta.dart';
import 'widgets/today_top_bar.dart';

class TodayView extends GetView<TodayController> {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        loading: const _TodaySkeleton(),
        errorMessage: controller.errorMessage,
        onRetry: controller.reload,
        child: _TodayContent(controller: controller),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final TodayController controller;
  const _TodayContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isNoBuckets) {
        return EmptyTodayNoBucketsBody(
          streak: controller.currentStreak,
          formattedDate: controller.formattedDate,
          onMakeBucket: controller.onMakeBucket,
        );
      }
      if (controller.isAllCaughtUp) {
        return EmptyTodayBody(
          streak: controller.currentStreak,
          formattedDate: controller.formattedDate,
          nextDropAt: controller.nextDropAt.value,
          hasNotes: controller.hasNotes,
          doneFastBanner: controller.doneFastBanner.value,
          onOpenQuiz: controller.openQuiz,
          onAddNote: controller.onAddNote,
        );
      }
      return _TodayLoaded(controller: controller);
    });
  }
}

class _TodayLoaded extends StatelessWidget {
  final TodayController controller;
  const _TodayLoaded({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Obx(() {
                      final _ = controller.profile.value;
                      return TodayTopBar(
                        streak: controller.currentStreak,
                        formattedDate: controller.formattedDate,
                      );
                    }),
                    const SizedBox(height: 22),
                    AnimatedBuilder(
                      animation: controller.ringController,
                      builder: (context, _) {
                        return Obx(() {
                          return TodayHeatRing(
                            dueCount: controller.dueCount.value,
                            progress: controller.ringProgress.value,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    // Stack sits right under the ring; the action dock (Aura
                    // whisper + Start CTA) is pushed to the bottom by Spacer.
                    Obx(() {
                      final nodes = controller.peekingNodes.toList();
                      return TodayPeekingStack(
                        nodes: nodes,
                        animation: controller.cardController,
                      );
                    }),
                    const Spacer(),
                    Obx(() {
                      if (!controller.showRelearn) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TodayRelearnCard(
                          count: controller.relearnCount,
                          isStarting: controller.isRelearnStarting.value,
                          onStart: controller.startRelearn,
                          onDismiss: controller.dismissRelearn,
                        ),
                      );
                    }),
                    Obx(() => TodayStartCta(
                          label: controller.isAtStackLimit
                              ? 'Unlock unlimited reviews'
                              : 'Start review',
                          isLoading: controller.isStarting.value,
                          onPressed: controller.isAtStackLimit
                              ? () => Get.toNamed('/paywall')
                              : controller.startReview,
                        )),
                    Obx(() {
                      if (!controller.isFree) return const SizedBox(height: 16);
                      return TodayStacksMeter(
                        stacksUsed: controller.stacksUsed.value,
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              RecallSkeleton(width: 140, height: 18, phase: 0),
              RecallSkeleton(width: 60, height: 14, phase: 0.2),
            ],
          ),
          const SizedBox(height: 24),
          const _RingSkeleton(phase: 0.35),
          const SizedBox(height: 30),
          SizedBox(
            height: 176,
            child: Stack(
              children: const [
                Positioned(
                  top: 0,
                  left: 18,
                  right: 18,
                  child: RecallSkeleton(
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    phase: 0.5,
                  ),
                ),
                Positioned(
                  top: 28,
                  left: 9,
                  right: 9,
                  child: RecallSkeleton(
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(23)),
                    phase: 0.65,
                  ),
                ),
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RecallSkeleton(
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(26)),
                    phase: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const RecallSkeleton(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
            phase: 0.9,
          ),
        ],
      ),
    );
  }
}

class _RingSkeleton extends StatefulWidget {
  final double phase;

  const _RingSkeleton({this.phase = 0});

  @override
  State<_RingSkeleton> createState() => _RingSkeletonState();
}

class _RingSkeletonState extends State<_RingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RecallMotion.shimmer,
  );

  @override
  void initState() {
    super.initState();
    _controller.value = widget.phase.clamp(0.0, 1.0);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final ring = SizedBox(
      width: 206,
      height: 206,
      child: CustomPaint(
        painter: _RingSkeletonPainter(
          color: c.grey300,
          trackColor: c.grey300,
        ),
      ),
    );

    if (reduceMotion) return Opacity(opacity: 0.7, child: ring);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: RecallMotion.easeInOut),
      ),
      child: ring,
    );
  }
}

class _RingSkeletonPainter extends CustomPainter {
  final Color color;
  final Color trackColor;

  _RingSkeletonPainter({required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 86.0;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.15,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingSkeletonPainter old) => false;
}
