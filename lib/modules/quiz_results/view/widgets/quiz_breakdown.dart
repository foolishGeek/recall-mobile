import 'package:flutter/material.dart';

import '../../../../core/widgets/soft_card.dart';
import '../../../../data/models/models.dart';
import 'quiz_breakdown_row.dart';
import 'quiz_section_header.dart';

/// "BREAKDOWN" — the per-question list. Each `node_id` question shows its
/// correctness; wrong rows expand inline with the right answer (+ AI feedback
/// for short answers). All data comes from `questions[]` [D-EF-3].
class QuizBreakdown extends StatelessWidget {
  final List<QuizResultQuestion> questions;

  const QuizBreakdown({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < questions.length; i++) {
      if (i > 0) rows.add(const QuizRowDivider());
      rows.add(QuizBreakdownRow(index: i + 1, question: questions[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizSectionHeader(title: 'Breakdown', note: '${questions.length} questions'),
        const SizedBox(height: 12),
        SoftCard(
          padding: EdgeInsets.zero,
          radius: 22,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}
