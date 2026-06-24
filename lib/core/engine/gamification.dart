// Recall · Level / XP curve [D-ENG-12].

import 'dart:math' as math;

import 'params/engine_config.dart';

int levelForXp(int xp, {EngineConfig config = EngineConfig.defaults}) =>
    (math.sqrt(xp / config.levelXpDivisor)).floor() + 1;

int levelThreshold(int level, {EngineConfig config = EngineConfig.defaults}) =>
    config.levelXpDivisor * (level - 1) * (level - 1);

int levelCap(int level, {EngineConfig config = EngineConfig.defaults}) =>
    config.levelXpDivisor * level * level;

int xpToNext(int xp, {EngineConfig config = EngineConfig.defaults}) {
  final level = levelForXp(xp, config: config);
  return levelCap(level, config: config) - xp;
}

double levelProgress(int xp, {EngineConfig config = EngineConfig.defaults}) {
  final level = levelForXp(xp, config: config);
  final threshold = levelThreshold(level, config: config);
  final cap = levelCap(level, config: config);
  final span = cap - threshold;
  if (span <= 0) return 1;
  return ((xp - threshold) / span).clamp(0.0, 1.0);
}
