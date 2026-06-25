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
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.ink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 10),
                blurRadius: 22,
              ),
            ],
          ),
          child: Icon(
            widget.locked ? Icons.lock_outline : Icons.add,
            size: 24,
            color: c.inkOnInk,
          ),
        ),
      ),
    );
  }
}
