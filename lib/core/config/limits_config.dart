// Free-tier numeric limits mirrored from `app_config`. Server remains truth;
// this drives gate UX only. Fetch-fail keeps the last known snapshot (canon is
// only the cold-start default before any successful fetch).
// Flip relaxed↔canon via SQL (`rollback_limits_to_canon`) — no app release.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/services/platform/supabase_service.dart';
import 'app_limits.dart';

class LimitsConfig extends GetxService {
  /// Reactive snapshot — Obx rebuilds when the whole [AppLimits] is replaced.
  final Rx<AppLimits> snapshot = AppLimits.canon.obs;

  AppLimits get current => snapshot.value;

  // Compatibility getters used during migration; prefer [snapshot] / [current].
  static const String profileCanon = AppLimits.profileCanon;
  static const String profileRelaxed = AppLimits.profileRelaxed;
  static const int canonStacks = AppLimits.canonStacks;
  static const int canonBuckets = AppLimits.canonBuckets;
  static const int canonAiQuota = AppLimits.canonAiQuota;
  static const int canonAiOverviews = AppLimits.canonAiOverviews;
  static const int canonSessionSize = AppLimits.canonSessionSize;

  /// Touch [snapshot] so Obx tracks profile flips (You / Insights pattern).
  RxString get profileRx {
    // Derived view: reading .value inside Obx still needs a dedicated Rx for
    // callers that only watch the profile string. Keep in sync with snapshot.
    return _profileRx;
  }

  final RxString _profileRx = AppLimits.profileCanon.obs;

  String get profile => current.profile;
  bool get isRelaxed => current.isRelaxed;
  int get stacksFreeMonthly => current.stacksFreeMonthly;
  int get bucketsFreeWritable => current.bucketsFreeWritable;
  int get aiQuotaFreeMonthly => current.aiQuotaFreeMonthly;
  int get aiOverviewFreeMonthly => current.aiOverviewFreeMonthly;
  int get sessionSizeFree => current.sessionSizeFree;
  bool get showStacksMeter => current.showStacksMeter;

  void applyCanon() => _set(AppLimits.canon);

  void applyRelaxed() => _set(AppLimits.relaxed);

  void _set(AppLimits next) {
    snapshot.value = next;
    _profileRx.value = next.profile;
  }

  Future<void> refresh() async {
    if (!Get.isRegistered<SupabaseService>()) {
      applyCanon();
      return;
    }
    try {
      final rows = await Get.find<SupabaseService>()
          .from('app_config')
          .select('key, value')
          .inFilter('key', const [
        'limits_profile',
        'stacks_free_monthly',
        'buckets_free_writable',
        'ai_quota_free_monthly',
        'ai_overview_free_monthly',
        'session_size_free',
      ]);

      final map = <String, dynamic>{};
      for (final row in rows as List) {
        final key = row['key']?.toString();
        if (key == null) continue;
        map[key] = row['value'];
      }

      final p = _asString(map['limits_profile']) ?? AppLimits.profileCanon;
      final base =
          p == AppLimits.profileRelaxed ? AppLimits.relaxed : AppLimits.canon;
      _set(base.copyWith(
        profile: p,
        stacksFreeMonthly:
            _asInt(map['stacks_free_monthly']) ?? base.stacksFreeMonthly,
        bucketsFreeWritable:
            _asInt(map['buckets_free_writable']) ?? base.bucketsFreeWritable,
        aiQuotaFreeMonthly:
            _asInt(map['ai_quota_free_monthly']) ?? base.aiQuotaFreeMonthly,
        aiOverviewFreeMonthly: _asInt(map['ai_overview_free_monthly']) ??
            base.aiOverviewFreeMonthly,
        sessionSizeFree:
            _asInt(map['session_size_free']) ?? base.sessionSizeFree,
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('[limits_config] $e');
      // Keep last known snapshot — do not wipe temporary-free on a blip.
    }
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.replaceAll('"', '');
    return v.toString().replaceAll('"', '');
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.replaceAll('"', ''));
    return int.tryParse(v.toString().replaceAll('"', ''));
  }
}
