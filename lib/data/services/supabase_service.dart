// Recall · SupabaseService. Owns the Supabase client lifecycle (init + raw
// access). Table CRUD + EF invoke land in S03; this S02 scope is bootstrap only.

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_env.dart';

class SupabaseService extends GetxService {
  /// Validates env and initializes the Supabase client. Throws
  /// [BootstrapException] on missing dart-defines so `main()` can surface a
  /// clear error instead of a silent white screen (sprint §6).
  static Future<SupabaseService> bootstrap() async {
    if (!AppEnv.hasSupabaseConfig) {
      throw const BootstrapException(
        'Missing Supabase configuration. Pass '
        '--dart-define-from-file=config/staging.json with SUPABASE_URL and '
        'SUPABASE_ANON_KEY set (see recall-backend/docs/DART-DEFINES.md).',
      );
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      // Supabase renamed the anon key to "publishable key"; our dart-define is
      // still SUPABASE_ANON_KEY (the publishable anon key) per DART-DEFINES.md.
      publishableKey: AppEnv.supabaseAnonKey,
    );

    return SupabaseService();
  }

  SupabaseClient get client => Supabase.instance.client;
}
