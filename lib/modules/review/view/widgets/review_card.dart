import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../../../data/models/enums.dart';
import 'review_direction_stamp.dart';

class ReviewCard extends StatefulWidget {
  final Widget child;
  final void Function(ReviewGrade grade) onRate;
  final ValueChanged<ReviewGrade?>? onDragGradeChanged;
  final VoidCallback? onThrowStarted;
  final bool enabled;

  const ReviewCard({
    super.key,
    required this.child,
    required this.onRate,
    this.onDragGradeChanged,
    this.onThrowStarted,
    this.enabled = true,
  });

  @override
  State<ReviewCard> createState() => ReviewCardState();
}

class ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _thresholdCrossed = false;
  bool _isThrowing = false;
  bool _rated = false;
  ReviewGrade? _pendingGrade;
  late final AnimationController _animController;
  Animation<Offset>? _offsetAnimation;
  VoidCallback? _tickListener;

  static const double _threshold = 28.0;
  static const double _throwThreshold = 120.0;
  static const double _velocityThreshold = 800.0;
  static const double _maxRotation = 12.0;
  static const Duration _throwDuration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _animController.addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _clearTickListener();
    _animController.removeStatusListener(_onAnimStatus);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;

    _clearTickListener();

    if (_isThrowing && _pendingGrade != null) {
      final grade = _pendingGrade!;
      _pendingGrade = null;
      // Keep the card at its thrown (off-screen) position; this card is about to
      // be replaced by the next one. Advance is deferred out of this animation
      // callback so the outgoing State can be disposed safely and the next card
      // mounts cleanly (no shared-state carryover, no mid-frame flicker).
      _rate(grade);
      return;
    }

    // Spring-back finished — same card stays, reset to center.
    setState(() {
      _dragOffset = Offset.zero;
      _thresholdCrossed = false;
      _offsetAnimation = null;
    });
    widget.onDragGradeChanged?.call(null);
  }

  void _rate(ReviewGrade grade) {
    if (_rated) return;
    _rated = true;
    scheduleMicrotask(() {
      if (!mounted) return;
      widget.onDragGradeChanged?.call(null);
      widget.onRate(grade);
    });
  }

  void _clearTickListener() {
    if (_tickListener != null) {
      _animController.removeListener(_tickListener!);
      _tickListener = null;
    }
  }

  void _bindTick() {
    _clearTickListener();
    _tickListener = () {
      if (_offsetAnimation == null || !mounted) return;
      setState(() => _dragOffset = _offsetAnimation!.value);
    };
    _animController.addListener(_tickListener!);
  }

  double get _rotation {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth == 0) return 0;
    return (_dragOffset.dx / screenWidth) * _maxRotation * (math.pi / 180);
  }

  double get _dragMagnitude => _dragOffset.distance;

  ReviewGrade? get _inferredGrade {
    if (_dragMagnitude < _threshold) return null;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? ReviewGrade.good : ReviewGrade.hard;
    }
    return dy < 0 ? ReviewGrade.easy : ReviewGrade.again;
  }

  double get _stampOpacity {
    if (_dragMagnitude < 30) return 0;
    return ((_dragMagnitude - 30) / (_throwThreshold - 30)).clamp(0.0, 0.78);
  }

  void _notifyDragGrade() {
    widget.onDragGradeChanged?.call(_inferredGrade);
  }

  // Grading swipe is horizontal-only so it never competes with the card body's
  // vertical scroll (long markdown). Easy/Forgot remain available via buttons,
  // which trigger vertical throws programmatically (no gesture conflict).
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isThrowing || _rated || !widget.enabled) return;
    setState(() {
      _dragOffset += Offset(details.delta.dx, 0);
    });

    if (!_thresholdCrossed && _dragOffset.dx.abs() >= _threshold) {
      _thresholdCrossed = true;
      RecallHaptics.selection();
    }
    _notifyDragGrade();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isThrowing || _rated || !widget.enabled) return;

    final speed = details.velocity.pixelsPerSecond.dx.abs();
    final grade = _inferredGrade;

    final shouldThrow = grade != null &&
        (_dragOffset.dx.abs() >= _throwThreshold || speed >= _velocityThreshold);

    if (shouldThrow) {
      _startThrow(grade);
    } else {
      _animateSpringBack();
    }
  }

  void _startThrow(ReviewGrade grade) {
    if (_isThrowing || _rated) return;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      widget.onThrowStarted?.call();
      _rate(grade);
      return;
    }

    setState(() {
      _isThrowing = true;
      _pendingGrade = grade;
    });
    widget.onThrowStarted?.call();

    final size = MediaQuery.sizeOf(context);
    const factor = 1.2;

    final Offset target = switch (grade) {
      ReviewGrade.good => Offset(size.width * factor, -40),
      ReviewGrade.hard => Offset(-size.width * factor, -40),
      ReviewGrade.easy => Offset(0, -size.height * factor),
      ReviewGrade.again => Offset(0, size.height * factor),
    };

    _animController.stop();
    _animController.duration = _throwDuration;
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInQuad,
    ));

    _bindTick();
    _animController.forward(from: 0);
  }

  void _animateSpringBack() {
    if (_dragOffset == Offset.zero) {
      widget.onDragGradeChanged?.call(null);
      return;
    }

    _animController.stop();
    _animController.duration = RecallMotion.normal;
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _bindTick();
    _animController.forward(from: 0);
  }

  /// Programmatic throw used by rating buttons (same path as swipe).
  void triggerThrow(ReviewGrade grade) {
    if (_isThrowing || _rated || !widget.enabled) return;

    final Offset startDrag = switch (grade) {
      ReviewGrade.good => const Offset(60, 0),
      ReviewGrade.hard => const Offset(-60, 0),
      ReviewGrade.easy => const Offset(0, -60),
      ReviewGrade.again => const Offset(0, 60),
    };

    setState(() {
      _dragOffset = startDrag;
      _thresholdCrossed = true;
    });
    widget.onDragGradeChanged?.call(grade);
    _startThrow(grade);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final transform = Matrix4.identity()
      ..translate(_dragOffset.dx, _dragOffset.dy)
      ..rotateZ(reduceMotion ? 0 : _rotation);

    final grade = _inferredGrade;

    final card = GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.grey200, width: 1),
                boxShadow: _isThrowing
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          offset: const Offset(0, 30),
                          blurRadius: 60,
                        ),
                        BoxShadow(
                          color: c.ink.withValues(alpha: 0.18),
                          blurRadius: 22,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          offset: const Offset(0, 14),
                          blurRadius: 30,
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(24),
              child: widget.child,
            ),
            if (grade != null && _stampOpacity > 0)
              ReviewDirectionStamp(
                grade: grade,
                opacity: _stampOpacity,
              ),
          ],
        ),
      ),
    );

    if (reduceMotion) return card;

    // Subtle entry: the new front card eases up from the ghost's scale.
    // Controller-free so it can never leave the card in a stuck state.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.97, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: card,
    );
  }
}
