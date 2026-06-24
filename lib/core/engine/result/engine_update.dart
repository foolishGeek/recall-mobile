// Recall · EngineUpdate — result of recordReview with audit fields [D-SCHEMA-4].

import '../../../data/models/node.dart';

class EngineUpdate {
  final Node node;
  final double? stabilityBefore;
  final double? stabilityAfter;
  final int difficultyBefore;
  final int difficultyAfter;
  final int comfortBefore;
  final int comfortAfter;
  final double retrievabilityBefore;
  final double retrievabilityAfter;
  final DateTime? dueBefore;
  final DateTime? dueAfter;

  const EngineUpdate({
    required this.node,
    this.stabilityBefore,
    this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.comfortBefore,
    required this.comfortAfter,
    required this.retrievabilityBefore,
    required this.retrievabilityAfter,
    this.dueBefore,
    this.dueAfter,
  });
}
