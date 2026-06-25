import 'package:flutter/material.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

class BucketsFab extends StatefulWidget {
  final bool locked;
  final VoidCallback onTap;

  const BucketsFab({
    super.key,
    required this.locked,
    required this.onTap,
  });

  @override
  State<BucketsFab> createState() => _BucketsFabState();
}

class _BucketsFabState extends State<BucketsFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: RecallMotion.fast,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _anim, curve: RecallMotion.bubbly),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _anim.forward();
  void _onTapUp(TapUpDetails _) {
    _anim.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _anim.reverse();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final locked = widget.locked;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  // Free-limit FAB inverts to a quiet hollow paper disc.
                  color: locked ? c.canvas : c.ink,
                  shape: BoxShape.circle,
                  border: locked ? Border.all(color: c.ink, width: 1.5) : null,
                  boxShadow: [
                    // Soft canvas halo so it floats over the grid.
                    BoxShadow(
                      color: c.canvas,
                      blurRadius: 0,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: locked ? 0.10 : 0.20),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  size: 26,
                  color: locked ? c.grey400 : c.inkOnInk,
                ),
              ),
              if (locked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.canvas, width: 2),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 11,
                      color: c.inkOnInk,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
