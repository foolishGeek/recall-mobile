// Recall · ConfigRepository — loads scheduling_params + app_config for engine.

import '../../core/engine/params/engine_config.dart';
import '../../core/engine/params/scheduling_params.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class ConfigRepository extends BaseRepository {
  ConfigRepository(SupabaseService supabase) : super(supabase, 'config');

  SchedulingParams? _schedulingParams;
  EngineConfig? _engineConfig;

  Future<SchedulingParams> fetchSchedulingParams({
    String? userId,
    String? bucketId,
  }) =>
      guard(() async {
        if (_schedulingParams != null &&
            userId == null &&
            bucketId == null) {
          return _schedulingParams!;
        }

        final global = await supabase
            .from('scheduling_params')
            .select()
            .isFilter('user_id', null)
            .isFilter('bucket_id', null)
            .maybeSingle();

        var params = global == null
            ? SchedulingParams.defaults
            : SchedulingParams.fromJson(global);

        if (userId != null) {
          final userRow = await supabase
              .from('scheduling_params')
              .select()
              .eq('user_id', userId)
              .isFilter('bucket_id', null)
              .maybeSingle();
          if (userRow != null) {
            params = _mergeParams(params, SchedulingParams.fromJson(userRow));
          }
        }

        if (bucketId != null) {
          final bucketRow = await supabase
              .from('scheduling_params')
              .select()
              .eq('bucket_id', bucketId)
              .maybeSingle();
          if (bucketRow != null) {
            params = _mergeParams(params, SchedulingParams.fromJson(bucketRow));
          }
        }

        if (userId == null && bucketId == null) {
          _schedulingParams = params;
        }
        return params;
      });

  Future<EngineConfig> fetchEngineConfig() => guard(() async {
        if (_engineConfig != null) return _engineConfig!;
        final rows = await supabase.from('app_config').select('key, value');
        final entries = <String, dynamic>{};
        for (final row in rows) {
          entries[row['key'] as String] = row['value'];
        }
        _engineConfig = EngineConfig.fromEntries(entries);
        return _engineConfig!;
      });

  void clearCache() {
    _schedulingParams = null;
    _engineConfig = null;
  }

  SchedulingParams _mergeParams(
    SchedulingParams base,
    SchedulingParams override,
  ) {
    return base.copyWith(
      targetRetention: override.targetRetention,
      w1: override.w1,
      w2: override.w2,
      w3: override.w3,
      w4: override.w4,
      w5: override.w5,
      w6: override.w6,
      w7: override.w7,
      w8: override.w8,
      sMin: override.sMin,
      comfortK: override.comfortK,
      hardPenalty: override.hardPenalty,
      easyBonus: override.easyBonus,
      newPerDay: override.newPerDay,
      sessionSize: override.sessionSize,
      maxNewPerStack: override.maxNewPerStack,
      maxPerBucket: override.maxPerBucket,
      lookaheadHours: override.lookaheadHours,
      temperature: override.temperature,
      dropThreshold: override.dropThreshold,
      leechLapseThreshold: override.leechLapseThreshold,
    );
  }
}
