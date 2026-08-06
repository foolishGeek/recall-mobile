// Recall · Tag model — `tags` row (user-scoped, unique on lower(name)).

import 'json_utils.dart';

class Tag {
  final String id;
  final String userId;
  final String name;
  final DateTime? createdAt;

  const Tag({
    required this.id,
    required this.userId,
    this.name = '',
    this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        name: asString(json['name']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'created_at': dateToJson(createdAt),
      };

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
