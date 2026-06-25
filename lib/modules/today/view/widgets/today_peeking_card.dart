import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/heat_dot.dart';
import '../../../../core/widgets/neo_chip.dart';
import '../../../../data/models/models.dart';

enum _CardTier { back, middle, front }

class TodayPeekingCard extends StatelessWidget {
  final DuePreviewNode node;
  final int index;
  final VoidCallback? onTap;

  const TodayPeekingCard({
    super.key,
    required this.node,
    required this.index,
    this.onTap,
  });

  _CardTier get _tier {
    if (index == 0) return _CardTier.back;
    if (index == 1) return _CardTier.middle;
    return _CardTier.front;
  }

  NeoLevel get _neoLevel {
    if (node.priority >= 4) return NeoLevel.high;
    if (node.priority >= 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  String get _priorityLabel {
    switch (_neoLevel) {
      case NeoLevel.high:
        return 'HIGH';
      case NeoLevel.medium:
        return 'MED';
      case NeoLevel.low:
        return 'LOW';
    }
  }

  String get _dueTimeLabel {
    final due = node.dueAt;
    if (due == null) return 'Due now';
    final diff = DateTime.now().toUtc().difference(due);
    if (diff.inDays > 0) {
      return 'Due ${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours > 0) {
      return 'Due ${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return 'Due ${diff.inMinutes}m ago';
    }
    return 'Due now';
  }

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: _tier == _CardTier.front
          ? _buildFrontCard(c, dark)
          : _buildCompactCard(c, dark),
    );
  }

  Widget _buildCompactCard(RecallColors c, bool dark) {
    final isBack = _tier == _CardTier.back;
    final radius = isBack ? 22.0 : 23.0;
    final shadowBlur = isBack ? 18.0 : 20.0;
    final shadowY = isBack ? 6.0 : 8.0;
    final shadowAlpha = dark
        ? (isBack ? 0.3 : 0.34)
        : (isBack ? 0.04 : 0.05);
    final titleColor = dark
        ? (isBack ? const Color(0xFF9D9B94) : const Color(0xFFCFCDC6))
        : (isBack ? const Color(0xFF5C5A55) : const Color(0xFF3A3935));

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            offset: Offset(0, shadowY),
            blurRadius: shadowBlur,
          ),
        ],
      ),
      child: Row(
        children: [
          HeatDot(heat: node.heat, size: 9),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              node.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          NeoChip.priority(_neoLevel, label: _priorityLabel),
        ],
      ),
    );
  }

  Widget _buildFrontCard(RecallColors c, bool dark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.09),
            offset: const Offset(0, 16),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  node.bucketName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.grey500,
                    letterSpacing: 10 * 0.2,
                  ),
                ),
              ),
              _FrontHeatDot(heat: node.heat, isDark: dark),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fraunces(
              fontSize: 27,
              fontWeight: FontWeight.w500,
              color: c.ink,
              height: 1.12,
              letterSpacing: 27 * -0.01,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeoChip.priority(
                _neoLevel,
                label: _priorityLabel,
              ).copyWithFront(),
              Text(
                _dueTimeLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: c.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrontHeatDot extends StatelessWidget {
  final double heat;
  final bool isDark;
  const _FrontHeatDot({required this.heat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final haloColor = isDark
        ? const Color(0xFFF5F4F1).withValues(alpha: 0.35)
        : const Color(0xFF111111).withValues(alpha: 0.3);
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: heat.clamp(0.0, 1.0)),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: haloColor,
            blurRadius: isDark ? 10 : 9,
          ),
        ],
      ),
    );
  }
}

extension _NeoChipFront on NeoChip {
  NeoChip copyWithFront() => NeoChip(
        label: label,
        color: color,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        fontSize: 10.5,
        borderRadius: 7,
      );
}
