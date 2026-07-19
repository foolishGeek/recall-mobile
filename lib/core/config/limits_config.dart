// Free-tier numeric limits mirrored from `app_config`. Server remains truth;
// this drives gate UX only. Fetch-fail falls back to canon (safe).
// Flip relaxed↔canon via SQL (`rollback_limits_to_canon`) — no app release.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/services/supabase_service.dart';

class LimitsConfig extends GetxService {
  /// Today's canon free caps ([D-PAY] / [D-AI] / [D-ENG-3]).
  static const String profileCanon = 'canon';
  static const String profileRelaxed = 'relaxed';

  static const int canonStacks = 2;
  static const int canonBuckets = 2;
  static const int canonAiQuota = 50;
  static const int canonAiOverviews = 2;
  static const int canonSessionSize = 8;

  static const int relaxedStacks = 999;
  static const int relaxedBuckets = 999;
  static const int relaxedAiQuota = 500;
  static const int relaxedAiOverviews = 50;
  static const int relaxedSessionSize = 12;

  /// Reactive so Obx screens pick up resume / splash refreshes.
  final RxString profileRx = profileCanon.obs;

  String get profile => profileRx.value;
  set profile(String v) => profileRx.value = v;

  int stacksFreeMonthly = canonStacks;
  int bucketsFreeWritable = canonBuckets;
  int aiQuotaFreeMonthly = canonAiQuota;
  int aiOverviewFreeMonthly = canonAiOverviews;
  int sessionSizeFree = canonSessionSize;

  bool get isRelaxed => profile == profileRelaxed;

  /// Hide discrete stack meters when the free cap is effectively uncapped.
  bool get showStacksMeter => stacksFreeMonthly <= 12;

  void applyCanon() {
    profile = profileCanon;
    stacksFreeMonthly = canonStacks;
    bucketsFreeWritable = canonBuckets;
    aiQuotaFreeMonthly = canonAiQuota;
    aiOverviewFreeMonthly = canonAiOverviews;
    sessionSizeFree = canonSessionSize;
  }

  void applyRelaxed() {
    profile = profileRelaxed;
    stacksFreeMonthly = relaxedStacks;
    bucketsFreeWritable = relaxedBuckets;
    aiQuotaFreeMonthly = relaxedAiQuota;
    aiOverviewFreeMonthly = relaxedAiOverviews;
    sessionSizeFree = relaxedSessionSize;
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

      final p = _asString(map['limits_profile']) ?? profileCanon;
      if (p == profileRelaxed) {
        applyRelaxed();
      } else {
        applyCanon();
      }
      profile = p;
      stacksFreeMonthly =
          _asInt(map['stacks_free_monthly']) ?? stacksFreeMonthly;
      bucketsFreeWritable =
          _asInt(map['buckets_free_writable']) ?? bucketsFreeWritable;
      aiQuotaFreeMonthly =
          _asInt(map['ai_quota_free_monthly']) ?? aiQuotaFreeMonthly;
      aiOverviewFreeMonthly =
          _asInt(map['ai_overview_free_monthly']) ?? aiOverviewFreeMonthly;
      sessionSizeFree = _asInt(map['session_size_free']) ?? sessionSizeFree;
    } catch (e) {
      if (kDebugMode) debugPrint('[limits_config] $e');
      applyCanon();
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
