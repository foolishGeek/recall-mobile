// Shared priority / difficulty / comfort labels + NeoLevel mapping for node chips.

import '../widgets/neo_chip.dart';

abstract class NodeMetadata {
  NodeMetadata._();

  static const priorityLabels = ['LOW', 'LOW', 'MED', 'HIGH', 'HIGH'];
  static const difficultyLabels = ['EASY', 'EASY', 'MED', 'HARD', 'HARD'];

  static String priorityLabel(int val) => priorityLabels[(val - 1).clamp(0, 4)];

  static String difficultyLabel(int val) =>
      difficultyLabels[(val - 1).clamp(0, 4)];

  static String comfortLabel(int val) {
    if (val <= 33) return 'LOW';
    if (val <= 66) return 'SO-SO';
    return 'COMFY';
  }

  static NeoLevel priorityLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  static NeoLevel difficultyLevel(int val) {
    if (val >= 4) return NeoLevel.high;
    if (val >= 3) return NeoLevel.medium;
    return NeoLevel.low;
  }

  /// Comfort NeoLevel: low comfort → high (red), high comfort → low (calm).
  static NeoLevel comfortLevel(int val) {
    if (val <= 33) return NeoLevel.high;
    if (val <= 66) return NeoLevel.medium;
    return NeoLevel.low;
  }
}
