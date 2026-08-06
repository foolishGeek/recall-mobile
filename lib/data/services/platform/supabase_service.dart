// Recall · SupabaseService. Owns the Supabase client lifecycle and is the single
// raw-I/O surface for the data layer: typed table access, RPC, and Edge Function
// invocation. Repositories call these (never the client directly) and wrap reads
// in BaseRepository.guard, which maps failures to RepoException [CANON §11].

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_env.dart';
import 'repo_exception.dart';

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

  GoTrueClient get auth => client.auth;

  /// The signed-in user's id, or null when there is no session.
  String? get currentUserId => client.auth.currentUser?.id;

  /// Typed table accessor. Repositories build queries off this and await them
  /// inside `BaseRepository.guard` so errors map to [RepoException].
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Calls a Postgres function (RPC). Errors are mapped to [RepoException].
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    try {
      return await client.rpc(fn, params: params);
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Invokes an Edge Function (e.g. `ai-forge`). Returns the JSON body as a map.
  /// Non-2xx responses surface as a [RepoException] with the EF error code.
  Future<Map<String, dynamic>> invokeFunction(
    String name, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await client.functions.invoke(name, body: body);
      final data = res.data;
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v));
      }
      return <String, dynamic>{'data': data};
    } catch (e, st) {
      throw mapError(e, st);
    }
  }
}
