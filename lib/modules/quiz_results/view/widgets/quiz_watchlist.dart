import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/models.dart';
import 'quiz_section_header.dart';

/// "WATCHLIST" — weak topics from the quiz (low comfort, high difficulty).
/// Tapping a row routes to that node. Source: `weak_topics[]` [D-EF-3].
class QuizWatchlist extends StatelessWidget {
  final List<QuizWeakTopic> topics;
  final ValueChanged<String> onTap;

  const QuizWatchlist({super.key, required this.topics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < topics.length; i++) {
      if (i > 0) rows.add(const QuizRowDivider());
      rows.add(_WatchRow(topic: topics[i], onTap: () => onTap(topics[i].nodeId)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QuizSectionHeader(title: 'Watchlist', note: 'Resurfaced sooner'),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          radius: 22,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

class _WatchRow extends StatelessWidget {
  final QuizWeakTopic topic;
  final VoidCallback onTap;
  const _WatchRow({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.ink.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  if (topic.bucketName != null && topic.bucketName!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      topic.bucketName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11.5, color: c.grey500),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.grey400),
          ],
        ),
      ),
    );
  }
}
