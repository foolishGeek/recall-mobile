import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';
import '../../../../core/utils/recall_haptics.dart';

class BucketFab extends StatefulWidget {
  final VoidCallback onTap;

  const BucketFab({super.key, required this.onTap});

  @override
  State<BucketFab> createState() => _BucketFabState();
}

class _BucketFabState extends State<BucketFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: RecallMotion.ctaPress,
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: RecallMotion.bubbly),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          RecallHaptics.light();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          height: 54,
          padding: const EdgeInsets.only(left: 18, right: 22),
          decoration: BoxDecoration(
            color: c.ink,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: c.canvas.withValues(alpha: 0.9),
                spreadRadius: 6,
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                offset: const Offset(0, 14),
                blurRadius: 28,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: c.inkOnInk),
              const SizedBox(width: 8),
              Text(
                'Node',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.inkOnInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
