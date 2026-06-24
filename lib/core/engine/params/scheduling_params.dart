// Recall · SchedulingParams — mirrors `scheduling_params` row defaults [S01].

import '../../../data/models/json_utils.dart';

class SchedulingParams {
  final double targetRetention;
  final double w1;
  final double w2;
  final double w3;
  final double w4;
  final double w5;
  final double w6;
  final double w7;
  final double w8;
  final double sMin;
  final double comfortK;
  final double hardPenalty;
  final double easyBonus;
  final int newPerDay;
  final int sessionSize;
  final int maxNewPerStack;
  final int maxPerBucket;
  final int lookaheadHours;
  final double temperature;
  final int dropThreshold;
  final int leechLapseThreshold;

  const SchedulingParams({
    this.targetRetention = 0.9,
    this.w1 = 0.4,
    this.w2 = 0.2,
    this.w3 = 0.8,
    this.w4 = 0.5,
    this.w5 = 0.5,
    this.w6 = 0.5,
    this.w7 = 0.2,
    this.w8 = 0.15,
    this.sMin = 0.1,
    this.comfortK = 21,
    this.hardPenalty = 0.8,
    this.easyBonus = 1.3,
    this.newPerDay = 5,
    this.sessionSize = 12,
    this.maxNewPerStack = 3,
    this.maxPerBucket = 6,
    this.lookaheadHours = 12,
    this.temperature = 1.2,
    this.dropThreshold = 5,
    this.leechLapseThreshold = 8,
  });

  static const defaults = SchedulingParams();

  factory SchedulingParams.fromJson(Map<String, dynamic> json) =>
      SchedulingParams(
        targetRetention: asDouble(json['target_retention'], 0.9),
        w1: asDouble(json['w1'], 0.4),
        w2: asDouble(json['w2'], 0.2),
        w3: asDouble(json['w3'], 0.8),
        w4: asDouble(json['w4'], 0.5),
        w5: asDouble(json['w5'], 0.5),
        w6: asDouble(json['w6'], 0.5),
        w7: asDouble(json['w7'], 0.2),
        w8: asDouble(json['w8'], 0.15),
        sMin: asDouble(json['s_min'], 0.1),
        comfortK: asDouble(json['comfort_k'], 21),
        hardPenalty: asDouble(json['hard_penalty'], 0.8),
        easyBonus: asDouble(json['easy_bonus'], 1.3),
        newPerDay: asInt(json['new_per_day'], 5),
        sessionSize: asInt(json['session_size'], 12),
        maxNewPerStack: asInt(json['max_new_per_stack'], 3),
        maxPerBucket: asInt(json['max_per_bucket'], 6),
        lookaheadHours: asInt(json['lookahead_hours'], 12),
        temperature: asDouble(json['temperature'], 1.2),
        dropThreshold: asInt(json['drop_threshold'], 5),
        leechLapseThreshold: asInt(json['leech_lapse_threshold'], 8),
      );

  SchedulingParams copyWith({
    double? targetRetention,
    double? w1,
    double? w2,
    double? w3,
    double? w4,
    double? w5,
    double? w6,
    double? w7,
    double? w8,
    double? sMin,
    double? comfortK,
    double? hardPenalty,
    double? easyBonus,
    int? newPerDay,
    int? sessionSize,
    int? maxNewPerStack,
    int? maxPerBucket,
    int? lookaheadHours,
    double? temperature,
    int? dropThreshold,
    int? leechLapseThreshold,
  }) {
    return SchedulingParams(
      targetRetention: targetRetention ?? this.targetRetention,
      w1: w1 ?? this.w1,
      w2: w2 ?? this.w2,
      w3: w3 ?? this.w3,
      w4: w4 ?? this.w4,
      w5: w5 ?? this.w5,
      w6: w6 ?? this.w6,
      w7: w7 ?? this.w7,
      w8: w8 ?? this.w8,
      sMin: sMin ?? this.sMin,
      comfortK: comfortK ?? this.comfortK,
      hardPenalty: hardPenalty ?? this.hardPenalty,
      easyBonus: easyBonus ?? this.easyBonus,
      newPerDay: newPerDay ?? this.newPerDay,
      sessionSize: sessionSize ?? this.sessionSize,
      maxNewPerStack: maxNewPerStack ?? this.maxNewPerStack,
      maxPerBucket: maxPerBucket ?? this.maxPerBucket,
      lookaheadHours: lookaheadHours ?? this.lookaheadHours,
      temperature: temperature ?? this.temperature,
      dropThreshold: dropThreshold ?? this.dropThreshold,
      leechLapseThreshold: leechLapseThreshold ?? this.leechLapseThreshold,
    );
  }
}
