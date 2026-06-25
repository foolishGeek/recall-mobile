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
  final bool enabled;

  const ReviewCard({
    super.key,
    required this.child,
    required this.onRate,
    this.enabled = true,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _thresholdCrossed = false;
  bool _isThrowing = false;
  late AnimationController _springController;
  Animation<Offset>? _springAnimation;
  Animation<Offset>? _throwAnimation;

  static const double _threshold = 28.0;
  static const double _throwThreshold = 120.0;
  static const double _velocityThreshold = 800.0;
  static const double _maxRotation = 12.0;
  static const Duration _throwDuration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  double get _rotation {
    final screenWidth = MediaQuery.of(context).size.width;
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
    } else {
      return dy < 0 ? ReviewGrade.easy : ReviewGrade.again;
    }
  }

  double get _stampOpacity {
    if (_dragMagnitude < 30) return 0;
    return ((_dragMagnitude - 30) / (_throwThreshold - 30)).clamp(0.0, 0.78);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isThrowing || !widget.enabled) return;
    setState(() {
      _dragOffset += details.delta;
    });

    if (!_thresholdCrossed && _dragMagnitude >= _threshold) {
      _thresholdCrossed = true;
      RecallHaptics.selection();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isThrowing || !widget.enabled) return;

    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    final grade = _inferredGrade;

    final shouldThrow = grade != null &&
        (_dragMagnitude >= _throwThreshold || speed >= _velocityThreshold);

    if (shouldThrow) {
      _animateThrow(grade);
    } else {
      _animateSpringBack();
    }
  }

  void _animateThrow(ReviewGrade grade) {
    setState(() => _isThrowing = true);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final factor = 1.2;

    Offset target;
    switch (grade) {
      case ReviewGrade.good:
        target = Offset(screenWidth * factor, -40);
        break;
      case ReviewGrade.hard:
        target = Offset(-screenWidth * factor, -40);
        break;
      case ReviewGrade.easy:
        target = Offset(0, -screenHeight * factor);
        break;
      case ReviewGrade.again:
        target = Offset(0, screenHeight * factor);
        break;
    }

    _springController.stop();
    _throwAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeInQuad,
    ));

    _springController.duration = _throwDuration;
    _springController.reset();

    _springController.addListener(_onThrowTick);
    _springController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _springController.removeListener(_onThrowTick);
        widget.onRate(grade);
        _resetCard();
      }
    });

    _springController.forward();
  }

  void _onThrowTick() {
    if (_throwAnimation != null) {
      setState(() {
        _dragOffset = _throwAnimation!.value;
      });
    }
  }

  void _animateSpringBack() {
    final startOffset = _dragOffset;
    _springAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(_springController);

    _springController.stop();
    _springController.duration = RecallMotion.normal;
    _springController.reset();

    _springController.addListener(_onSpringTick);
    _springController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _springController.removeListener(_onSpringTick);
        setState(() {
          _dragOffset = Offset.zero;
          _thresholdCrossed = false;
        });
      }
    });

    _springController.forward();
  }

  void _onSpringTick() {
    if (_springAnimation != null) {
      setState(() {
        _dragOffset = _springAnimation!.value;
      });
    }
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _thresholdCrossed = false;
      _isThrowing = false;
      _throwAnimation = null;
      _springAnimation = null;
    });
  }

  void triggerThrow(ReviewGrade grade) {
    if (_isThrowing) return;
    Offset startDrag;
    switch (grade) {
      case ReviewGrade.good:
        startDrag = const Offset(60, 0);
        break;
      case ReviewGrade.hard:
        startDrag = const Offset(-60, 0);
        break;
      case ReviewGrade.easy:
        startDrag = const Offset(0, -60);
        break;
      case ReviewGrade.again:
        startDrag = const Offset(0, 60);
        break;
    }
    setState(() => _dragOffset = startDrag);
    _animateThrow(grade);
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

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
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
  }
}
