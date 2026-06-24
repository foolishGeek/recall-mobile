// Recall · NotificationRepository. Writes client-allowed notification events
// (`delivered`/`opened` — enforced by 00003 RLS) and device tokens; reads recent
// events. Returns models only.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository(SupabaseService supabase)
      : super(supabase, 'notifications');

  /// Records a `delivered`/`opened` event, idempotent on (dedupe_key, type).
  Future<void> recordEvent({
    required String userId,
    required NotificationEventType type,
    required String dedupeKey,
    String? stackId,
    Map<String, dynamic> metadata = const {},
  }) =>
      guard(() async {
        await supabase.from('notification_events').upsert(
          {
            'user_id': userId,
            'type': type.wire,
            'dedupe_key': dedupeKey,
            if (stackId != null) 'stack_id': stackId,
            'metadata': metadata,
          },
          onConflict: 'dedupe_key,type',
          ignoreDuplicates: true,
        );
      });

  Future<List<NotificationEvent>> fetchRecent(String userId, {int limit = 50}) =>
      guard(() async {
        final rows = await supabase
            .from('notification_events')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return mapList(rows, NotificationEvent.fromJson);
      });

  /// Registers/refreshes an FCM device token (unique per user_id+token).
  Future<void> registerDeviceToken({
    required String userId,
    required DevicePlatform platform,
    required String token,
  }) =>
      guard(() async {
        await supabase.from('device_tokens').upsert(
          {
            'user_id': userId,
            'platform': platform.wire,
            'token': token,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,token',
        );
      });
}
