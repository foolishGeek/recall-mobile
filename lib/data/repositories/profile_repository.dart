// Recall · ProfileRepository. Reads the profile + subscription; the client may
// only update preference columns (gamification/AI/billing columns are locked by
// migration 00003 and written server-side).

import '../local/local_store.dart';
import '../models/models.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(this._local, SupabaseService supabase)
      : super(supabase, 'profile');

  final LocalStore _local;

  Future<Profile?> fetchProfile(String userId) => guard(() async {
        final row = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : Profile.fromJson(row);
      });

  /// Ensures `profiles` + `subscriptions` exist for the signed-in user (S09).
  /// Idempotent — safe on every cold start and after OAuth sign-in.
  Future<bool> ensureProfile() => guard(() async {
        final result = await supabase.rpc('ensure_profile_rpc');
        final map = asJsonMap(result);
        return map['created'] == true;
      });

  Future<Subscription?> fetchSubscription(String userId) => guard(() async {
        final row = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        return row == null ? null : Subscription.fromJson(row);
      });

  /// Re-reads the server-authoritative entitlement state (subscription + the
  /// profile that carries `had_premium` / `ai_credit_balance`). The paywall
  /// polls this after a purchase until the `revenuecat-webhook` has flipped the
  /// tier or topped up credits.
  Future<({Subscription? subscription, Profile? profile})> refreshEntitlement(
    String userId,
  ) async {
    final results = await Future.wait([
      fetchSubscription(userId),
      fetchProfile(userId),
    ]);
    return (
      subscription: results[0] as Subscription?,
      profile: results[1] as Profile?,
    );
  }

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

  /// Tries a live update; on offline queues prefs for replay on reconnect [S09].
  Future<Profile?> updatePreferencesResilient(
    String userId,
    Map<String, dynamic> changes, {
    Profile? current,
  }) async {
    if (changes['onboarding_done'] == true) {
      await _local.setCachedOnboardingDone(userId, true);
    }
    try {
      return await updatePreferences(userId, changes);
    } on RepoException catch (e) {
      if (!e.isOffline) rethrow;
      await _local.enqueueProfilePrefs(userId, changes);
      return current?.copyWith(
        onboardingDone: changes['onboarding_done'] as bool? ??
            current.onboardingDone,
        pushOptIn:
            changes['push_opt_in'] as bool? ?? current.pushOptIn,
        dropFrequency: changes['drop_frequency'] as String? ??
            current.dropFrequency,
      );
    }
  }

  /// Resolves whether onboarding is complete: local cache, pending queue, then
  /// server profile (after optional profile-prefs flush by caller).
  Future<bool> resolveOnboardingDone(String userId) async {
    if (await _local.cachedOnboardingDone(userId)) return true;
    if (await _local.hasPendingOnboardingDone(userId)) return true;
    final profile = await fetchProfile(userId);
    final serverDone = profile?.onboardingDone ?? false;
    if (serverDone) {
      await _local.setCachedOnboardingDone(userId, true);
    }
    return serverDone;
  }

  Future<int> fetchStacksCreatedThisMonth(String userId) => guard(() async {
        final value = await supabase.rpc('current_stack_usage_rpc');
        return asInt(value);
      });
}
