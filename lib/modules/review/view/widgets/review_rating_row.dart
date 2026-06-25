import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../data/models/enums.dart';

class ReviewRatingRow extends StatelessWidget {
  final void Function(ReviewGrade grade) onRate;
  final String Function(ReviewGrade grade) intervalLabel;
  final bool isLastCard;
  final ReviewGrade? activeGrade;

  const ReviewRatingRow({
    super.key,
    required this.onRate,
    required this.intervalLabel,
    this.isLastCard = false,
    this.activeGrade,
  });

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
              _buildButton(context, c, dark, ReviewGrade.again, _forgotIcon),
              const SizedBox(width: 8),
              _buildButton(context, c, dark, ReviewGrade.hard, _hardIcon),
              const SizedBox(width: 8),
              _buildButton(context, c, dark, ReviewGrade.good, _goodIcon),
              const SizedBox(width: 8),
              _buildButton(context, c, dark, ReviewGrade.easy, _easyIcon),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLastCard ? 'LAST ONE \u2192' : 'SWIPE \u2190 HARDER \u00B7 EASIER \u2192',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 10 * 0.18,
              color: c.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    RecallColors c,
    bool dark,
    ReviewGrade grade,
    Widget Function(Color) iconBuilder,
  ) {
    final isPrimary = grade == ReviewGrade.good;
    final isActive = activeGrade == grade || (activeGrade == null && isPrimary);
    final label = _gradeLabel(grade);
    final interval = intervalLabel(grade);

    final bg = isActive ? c.ink : c.card;
    final fg = isActive ? c.inkOnInk : c.ink;
    final shadow = isActive
        ? BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
            offset: const Offset(0, 8),
            blurRadius: 18,
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          );

    return Expanded(
      child: GestureDetector(
        onTap: () => onRate(grade),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 62,
          transform: isActive
              ? (Matrix4.identity()..scale(1.04, 1.04))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: c.ink, width: 1.5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [shadow],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBuilder(fg),
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
                    color: isActive
                        ? fg.withValues(alpha: 0.7)
                        : c.grey500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _gradeLabel(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.again:
        return 'Forgot';
      case ReviewGrade.hard:
        return 'Hard';
      case ReviewGrade.good:
        return 'Good';
      case ReviewGrade.easy:
        return 'Easy';
    }
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
