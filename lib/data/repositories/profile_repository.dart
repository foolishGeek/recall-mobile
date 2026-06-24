// Recall · ProfileRepository. Reads the profile + subscription; the client may
// only update preference columns (gamification/AI/billing columns are locked by
// migration 00003 and written server-side).

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(SupabaseService supabase) : super(supabase, 'profile');

  Future<Profile?> fetchProfile(String userId) => guard(() async {
        final row = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : Profile.fromJson(row);
      });

  Future<Subscription?> fetchSubscription(String userId) => guard(() async {
        final row = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        return row == null ? null : Subscription.fromJson(row);
      });

  /// Updates user-editable preference columns only. [changes] must contain
  /// pref keys (timezone, theme, display_name, ...); any locked column would be
  /// rejected by the column grants and surface as `unauthorized`.
  Future<Profile> updatePreferences(
    String userId,
    Map<String, dynamic> changes,
  ) =>
      guard(() async {
        final row = await supabase
            .from('profiles')
            .update(changes)
            .eq('id', userId)
            .select()
            .single();
        return Profile.fromJson(row);
      });
}
