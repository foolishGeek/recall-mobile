// Recall · EngineConfig — engine-relevant `app_config` keys [D-SCHEMA-7].

import '../../../data/models/json_utils.dart';

class EngineConfig {
  final int sessionSizeFree;
  final int learningStepMinutes;
  final double editSoftReduceFactor;
  final int levelXpDivisor;
  final int dropBudgetDaily;
  final int dropBudget3xwk;
  final int dropBudgetWeekly;

  const EngineConfig({
    this.sessionSizeFree = 8,
    this.learningStepMinutes = 10,
    this.editSoftReduceFactor = 1.0,
    this.levelXpDivisor = 100,
    this.dropBudgetDaily = 7,
    this.dropBudget3xwk = 3,
    this.dropBudgetWeekly = 1,
  });

  static const defaults = EngineConfig();

  factory EngineConfig.fromEntries(Map<String, dynamic> entries) {
    T read<T>(String key, T Function(Object?) parse, T fallback) {
      if (!entries.containsKey(key)) return fallback;
      return parse(entries[key]);
    }

    return EngineConfig(
      sessionSizeFree: read('session_size_free', (v) => asInt(v, 8), 8),
      learningStepMinutes:
          read('learning_step_minutes', (v) => asInt(v, 10), 10),
      editSoftReduceFactor:
          read('edit_soft_reduce_factor', (v) => asDouble(v, 1.0), 1.0),
      levelXpDivisor: read('level_xp_divisor', (v) => asInt(v, 100), 100),
      dropBudgetDaily: read('drop_budget_daily', (v) => asInt(v, 7), 7),
      dropBudget3xwk: read('drop_budget_3xwk', (v) => asInt(v, 3), 3),
      dropBudgetWeekly: read('drop_budget_weekly', (v) => asInt(v, 1), 1),
    );
  }

  int dropBudgetForFrequency(String frequency) {
    switch (frequency) {
      case '3xwk':
        return dropBudget3xwk;
      case 'weekly':
        return dropBudgetWeekly;
      default:
        return dropBudgetDaily;
    }
  }
}
