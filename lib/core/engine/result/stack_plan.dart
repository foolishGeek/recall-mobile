// Recall · StackPlan — pure stack generation result (persisted by services).

import '../../../data/models/node.dart';

class StackSelection {
  final Node node;
  final double heatSnapshot;
  final int position;

  const StackSelection({
    required this.node,
    required this.heatSnapshot,
    required this.position,
  });
}

class StackPlan {
  final List<StackSelection> items;
  final int newCount;
  final bool backlogCapped;
  final List<String> cooledBucketIds;

  const StackPlan({
    required this.items,
    this.newCount = 0,
    this.backlogCapped = false,
    this.cooledBucketIds = const [],
  });
}
