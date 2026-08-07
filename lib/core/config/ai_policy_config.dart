// AI entitlement policy mirrored from `v_ai_policy`. Server remains truth; this
// snapshot only drives gate UX. The view already filters to the active limits
// profile, so the app never decides canon vs relaxed itself.
// Fetch-fail keeps the last known snapshot (canon is only the cold-start
// default before any successful fetch), matching LimitsConfig.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/services/platform/supabase_service.dart';
import 'ai_policy.dart';

class AiPolicyConfig extends GetxService {
  /// Reactive snapshot — Obx rebuilds when the whole [AiPolicy] is replaced.
  final Rx<AiPolicy> snapshot = AiPolicy.canon.obs;

  AiPolicy get current => snapshot.value;

  Future<void> refresh() async {
    if (!Get.isRegistered<SupabaseService>()) return;
    try {
      final rows = await Get.find<SupabaseService>().from('v_ai_policy').select();

      final parsed = <String, AiFeaturePolicy>{};
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final feature = map['feature']?.toString();
        if (feature == null) continue;
        parsed[feature] = AiFeaturePolicy.fromRow(map);
      }

      // An empty result means the table has not been seeded; keep canon rather
      // than unlocking every gated feature.
      if (parsed.isEmpty) return;
      snapshot.value = AiPolicy(parsed);
    } catch (e) {
      if (kDebugMode) debugPrint('[ai_policy_config] $e');
    }
  }
}
