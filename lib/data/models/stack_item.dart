// Recall · StackItem model — `stack_items` row (ordered node in a stack).

import 'json_utils.dart';

class StackItem {
  final String id;
  final String stackId;
  final String nodeId;
  final int position;
  final bool reviewed;

  const StackItem({
    required this.id,
    required this.stackId,
    required this.nodeId,
    this.position = 0,
    this.reviewed = false,
  });

  factory StackItem.fromJson(Map<String, dynamic> json) => StackItem(
        id: asString(json['id']),
        stackId: asString(json['stack_id']),
        nodeId: asString(json['node_id']),
        position: asInt(json['position']),
        reviewed: asBool(json['reviewed']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stack_id': stackId,
        'node_id': nodeId,
        'position': position,
        'reviewed': reviewed,
      };

  StackItem copyWith({
    String? id,
    String? stackId,
    String? nodeId,
    int? position,
    bool? reviewed,
  }) {
    return StackItem(
      id: id ?? this.id,
      stackId: stackId ?? this.stackId,
      nodeId: nodeId ?? this.nodeId,
      position: position ?? this.position,
      reviewed: reviewed ?? this.reviewed,
    );
  }
}
