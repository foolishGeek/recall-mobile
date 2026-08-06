// Recall · Achievement model — `achievements` row (12-item canonical seed).

import 'json_utils.dart';

class Achievement {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.slug,
    this.title = '',
    this.description,
    this.xpReward = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: asString(json['id']),
        slug: asString(json['slug']),
        title: asString(json['title']),
        description: asStringOrNull(json['description']),
        xpReward: asInt(json['xp_reward']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'xp_reward': xpReward,
      };

  Achievement copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
    );
  }
}
