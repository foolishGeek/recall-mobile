// Recall · NotificationEvent model — `notification_events` row. Clients write
// only `delivered`/`opened` [D-EF-10] (enforced by RLS in migration 00003).
// `metadata` is freeform jsonb, kept as a typed map.

import 'enums.dart';
import 'json_utils.dart';

class NotificationEvent {
  final String id;
  final String userId;
  final NotificationEventType type;
  final String dedupeKey;
  final String? stackId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const NotificationEvent({
    required this.id,
    required this.userId,
    required this.type,
    this.dedupeKey = '',
    this.stackId,
    this.metadata = const {},
    this.createdAt,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) =>
      NotificationEvent(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        type: NotificationEventType.fromWire(json['type']),
        dedupeKey: asString(json['dedupe_key']),
        stackId: asStringOrNull(json['stack_id']),
        metadata: asJsonMap(json['metadata']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.wire,
        'dedupe_key': dedupeKey,
        'stack_id': stackId,
        'metadata': metadata,
        'created_at': dateToJson(createdAt),
      };

  NotificationEvent copyWith({
    String? id,
    String? userId,
    NotificationEventType? type,
    String? dedupeKey,
    String? stackId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      stackId: stackId ?? this.stackId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
