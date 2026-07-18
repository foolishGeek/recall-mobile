import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/enums.dart';

/// Two primary actions (Forgot / Got it) plus an expandable More for Hard & Easy.
class ReviewRatingRow extends StatefulWidget {
  final void Function(ReviewGrade grade) onRate;
  final String Function(ReviewGrade grade) intervalLabel;
  final bool isLastCard;
  final ReviewGrade? activeGrade;
  final bool enabled;

  const ReviewRatingRow({
    super.key,
    required this.onRate,
    required this.intervalLabel,
    this.isLastCard = false,
    this.activeGrade,
    this.enabled = true,
  });

  @override
  State<ReviewRatingRow> createState() => _ReviewRatingRowState();
}

class _ReviewRatingRowState extends State<ReviewRatingRow>
    with SingleTickerProviderStateMixin {
  bool _moreExpanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleMore() {
    if (!widget.enabled) return;
    setState(() => _moreExpanded = !_moreExpanded);
    if (_moreExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _rate(ReviewGrade grade) {
    if (!widget.enabled) return;
    if (_moreExpanded) {
      setState(() => _moreExpanded = false);
      _expandController.reverse();
    }
    widget.onRate(grade);
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _GradeButton(
                  label: 'Forgot',
                  interval: widget.intervalLabel(ReviewGrade.again),
                  icon: _forgotIcon,
                  primary: false,
                  active: widget.activeGrade == ReviewGrade.again,
                  enabled: widget.enabled,
                  dark: dark,
                  colors: c,
                  onTap: () => _rate(ReviewGrade.again),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _GradeButton(
                  label: 'Got it',
                  interval: widget.intervalLabel(ReviewGrade.good),
                  icon: _goodIcon,
                  primary: true,
                  active: widget.activeGrade == ReviewGrade.good,
                  enabled: widget.enabled,
                  dark: dark,
                  colors: c,
                  onTap: () => _rate(ReviewGrade.good),
                ),
              ),
              const SizedBox(width: 10),
              _MoreButton(
                expanded: _moreExpanded,
                enabled: widget.enabled,
                colors: c,
                dark: dark,
                onTap: _toggleMore,
              ),
            ],
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _GradeButton(
                      label: 'Hard',
                      interval: widget.intervalLabel(ReviewGrade.hard),
                      icon: _hardIcon,
                      primary: false,
                      active: widget.activeGrade == ReviewGrade.hard,
                      enabled: widget.enabled,
                      dark: dark,
                      colors: c,
                      onTap: () => _rate(ReviewGrade.hard),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradeButton(
                      label: 'Easy',
                      interval: widget.intervalLabel(ReviewGrade.easy),
                      icon: _easyIcon,
                      primary: true,
                      active: widget.activeGrade == ReviewGrade.easy,
                      enabled: widget.enabled,
                      dark: dark,
                      colors: c,
                      onTap: () => _rate(ReviewGrade.easy),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isLastCard
                ? 'LAST ONE \u2192'
                : 'SWIPE \u2192 GOT IT \u00B7 \u2190 HARD \u00B7 MORE FOR EASY',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 10 * 0.12,
              color: c.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _forgotIcon(Color color) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _ForgotIconPainter(color: color),
    );
  }

  Widget _hardIcon(Color color) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Container(width: 14, height: 1.8, color: color),
      ),
    );
  }

  Widget _goodIcon(Color color) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _CheckIconPainter(color: color),
    );
  }

  Widget _easyIcon(Color color) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _EasyIconPainter(color: color),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final bool expanded;
  final bool enabled;
  final RecallColors colors;
  final bool dark;
  final VoidCallback onTap;

  const _MoreButton({
    required this.expanded,
    required this.enabled,
    required this.colors,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = colors.ink;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        height: 62,
        decoration: BoxDecoration(
          color: expanded ? colors.ink.withValues(alpha: 0.08) : colors.card,
          border: Border.all(color: colors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.close : Icons.more_horiz,
              size: 22,
              color: enabled ? fg : fg.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 2),
            Text(
              'More',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: enabled ? fg : fg.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final String label;
  final String interval;
  final Widget Function(Color) icon;
  final bool primary;
  final bool active;
  final bool enabled;
  final bool dark;
  final RecallColors colors;
  final VoidCallback onTap;

  const _GradeButton({
    required this.label,
    required this.interval,
    required this.icon,
    required this.primary,
    required this.active,
    required this.enabled,
    required this.dark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = primary || active;
    final bg = filled ? colors.ink : colors.card;
    final fg = filled ? colors.inkOnInk : colors.ink;
    final opacity = enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 62,
          transform: active
              ? (Matrix4.identity()..scale(1.03, 1.03))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: colors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: filled
                      ? (dark ? 0.45 : 0.18)
                      : (dark ? 0.3 : 0.04),
                ),
                offset: Offset(0, filled ? 8 : 4),
                blurRadius: filled ? 18 : 12,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon(fg),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 11.5 * 0.02,
                  color: fg,
                ),
              ),
              if (interval.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  interval,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: filled ? fg.withValues(alpha: 0.7) : colors.grey500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotIconPainter extends CustomPainter {
  final Color color;
  _ForgotIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, -0.5, 4.5, false, paint);

    final path = Path()
      ..moveTo(2, 2)
      ..lineTo(2, 6.5)
      ..lineTo(6.5, 6.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ForgotIconPainter old) => old.color != color;
}

class _CheckIconPainter extends CustomPainter {
  final Color color;
  _CheckIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(3, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..lineTo(size.width - 3, size.height * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckIconPainter old) => old.color != color;
}

class _EasyIconPainter extends CustomPainter {
  final Color color;
  _EasyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(3, size.height * 0.6)
      ..lineTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.6);

    final path2 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.75)
      ..lineTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width - 3, size.height * 0.75);

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _EasyIconPainter old) => old.color != color;
}
