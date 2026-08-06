// Recall · Stack model — `stacks` row. `scope` jsonb holds the bucket ids the
// stack was generated from; parsed into a typed list.

import 'enums.dart';
import 'json_utils.dart';

class Stack {
  final String id;
  final String userId;
  final List<String> scopeBucketIds;
  final StackStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Stack({
    required this.id,
    required this.userId,
    this.scopeBucketIds = const [],
    this.status = StackStatus.active,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Stack.fromJson(Map<String, dynamic> json) {
    final scope = asJsonMap(json['scope']);
    return Stack(
      id: asString(json['id']),
      userId: asString(json['user_id']),
      scopeBucketIds: asStringList(scope['bucket_ids']),
      status: StackStatus.fromWire(json['status']),
      startedAt: asDateTime(json['started_at']),
      completedAt: asDateTime(json['completed_at']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'scope': {'bucket_ids': scopeBucketIds},
        'status': status.wire,
        'started_at': dateToJson(startedAt),
        'completed_at': dateToJson(completedAt),
        'created_at': dateToJson(createdAt),
        'updated_at': dateToJson(updatedAt),
      };

  Stack copyWith({
    String? id,
    String? userId,
    List<String>? scopeBucketIds,
    StackStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stack(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scopeBucketIds: scopeBucketIds ?? this.scopeBucketIds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
