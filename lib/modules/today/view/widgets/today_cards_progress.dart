import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_motion.dart';

/// Today hero — how much of this session is left, as an editorial fraction over
/// a two-tone bar. Ink is what's still owed; surface is what's already cleared.
class TodayCardsProgress extends StatefulWidget {
  final int remaining;
  final int total;

  const TodayCardsProgress({
    super.key,
    required this.remaining,
    required this.total,
  });

  double get _cleared {
    if (total <= 0) return 0;
    return ((total - remaining) / total).clamp(0.0, 1.0);
  }

  @override
  State<TodayCardsProgress> createState() => _TodayCardsProgressState();
}

class _TodayCardsProgressState extends State<TodayCardsProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RecallMotion.slow,
  );

  late final Animation<double> _bar = CurvedAnimation(
    parent: _controller,
    curve: RecallMotion.easeInOut,
  );

  // Header settles before the bar finishes drawing, so the number reads first.
  late final Animation<double> _header = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.76, curve: RecallMotion.easeInOut),
  );

  double _from = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value == 0) _play();
  }

  @override
  void didUpdateWidget(covariant TodayCardsProgress old) {
    super.didUpdateWidget(old);
    if (old._cleared != widget._cleared) {
      _from = old._cleared;
      _play();
    }
  }

  void _play() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: _header.value,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - _header.value)),
                child: _Header(
                  remaining: widget.remaining,
                  total: widget.total,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ProgressBar(
              cleared: _from + (widget._cleared - _from) * _bar.value,
              clearedColor: dark ? c.grey300 : c.card,
              remainingColor: c.ink,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int remaining;
  final int total;

  const _Header({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              // A fraction only earns its place once something is cleared;
              // untouched sessions read as a single, calmer number.
              remaining == total ? '$remaining' : '$remaining/$total',
              style: GoogleFonts.fraunces(
                fontSize: 58,
                fontWeight: FontWeight.w500,
                color: c.ink,
                height: 0.9,
                letterSpacing: 58 * -0.02,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cards',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: c.grey600,
                letterSpacing: 15.5 * -0.01,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'ready when you are',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: c.grey500,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double cleared;
  final Color clearedColor;
  final Color remainingColor;

  const _ProgressBar({
    required this.cleared,
    required this.clearedColor,
    required this.remainingColor,
  });

  /// A short rule under the number, not a full-width meter — it reads as
  /// punctuation for the hero rather than a dashboard gauge.
  static const _width = 104.0;
  static const _height = 3.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: remainingColor)),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _width * cleared.clamp(0.0, 1.0),
              child: ColoredBox(color: clearedColor),
            ),
          ],
        ),
      ),
    );
  }
}
