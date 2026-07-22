// Recall · Bucket model — `buckets` row. `heat_summary` parses into a typed
// HeatSummary; `cooling_period` is kept as raw interval text (+ Duration getter).

import 'heat_summary.dart';
import 'json_utils.dart';

class Bucket {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String coolingPeriod; // raw Postgres interval text
  final String frequency;
  final DateTime? cooldownUntil;
  final HeatSummary heatSummary;
  final double? masteryPct;
  final int? dailyCap;

  /// Default spaced-revision state applied to NEW notes created in this bucket.
  /// The bucket toggle also drives the "skip this whole bucket" bulk action.
  /// Note eligibility itself keys on `Node.srEnabled` (backend 00045/00046).
  final bool srEnabled;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Bucket({
    required this.id,
    required this.userId,
    this.name = '',
    this.description,
    this.coolingPeriod = '24:00:00',
    this.frequency = 'daily',
    this.cooldownUntil,
    this.heatSummary = HeatSummary.empty,
    this.masteryPct,
    this.dailyCap,
    this.srEnabled = true,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  Duration? get coolingPeriodDuration => parseInterval(coolingPeriod);

  factory Bucket.fromJson(Map<String, dynamic> json) => Bucket(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        name: asString(json['name']),
        description: asStringOrNull(json['description']),
        coolingPeriod: asString(json['cooling_period'], '24:00:00'),
        frequency: asString(json['frequency'], 'daily'),
        cooldownUntil: asDateTime(json['cooldown_until']),
        heatSummary: HeatSummary.fromJson(asJsonMap(json['heat_summary'])),
        masteryPct: asDoubleOrNull(json['mastery_pct']),
        dailyCap: asIntOrNull(json['daily_cap']),
        srEnabled: asBool(json['sr_enabled'], true),
        deletedAt: asDateTime(json['deleted_at']),
        createdAt: asDateTime(json['created_at']),
        updatedAt: asDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'cooling_period': coolingPeriod,
        'frequency': frequency,
        'cooldown_until': dateToJson(cooldownUntil),
        'heat_summary': heatSummary.toJson(),
        'mastery_pct': masteryPct,
        'daily_cap': dailyCap,
        'sr_enabled': srEnabled,
        'deleted_at': dateToJson(deletedAt),
        'created_at': dateToJson(createdAt),
        'updated_at': dateToJson(updatedAt),
      };

  Bucket copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? coolingPeriod,
    String? frequency,
    DateTime? cooldownUntil,
    HeatSummary? heatSummary,
    double? masteryPct,
    int? dailyCap,
    bool? srEnabled,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bucket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coolingPeriod: coolingPeriod ?? this.coolingPeriod,
      frequency: frequency ?? this.frequency,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      heatSummary: heatSummary ?? this.heatSummary,
      masteryPct: masteryPct ?? this.masteryPct,
      dailyCap: dailyCap ?? this.dailyCap,
      srEnabled: srEnabled ?? this.srEnabled,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
