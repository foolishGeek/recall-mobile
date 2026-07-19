// Recall · environment. Reads compile-time dart-defines (passed via
// --dart-define-from-file=config/<flavor>.json). See recall-backend/docs/DART-DEFINES.md.

import 'package:package_info_plus/package_info_plus.dart';

class AppEnv {
  const AppEnv._();

  static const env = String.fromEnvironment('ENV', defaultValue: 'staging');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const revenueCatApiKey =
      String.fromEnvironment('REVENUECAT_API_KEY');

  /// Sentry release tag — hydrated from PackageInfo at boot.
  static String release = 'recall@1.0.0+2';

  static bool get isProd => env == 'prod';

  /// True when the minimum keys needed to boot Supabase are present.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sync [release] with the binary version (pubspec / Play versionCode).
  static Future<void> hydrateRelease() async {
    try {
      final info = await PackageInfo.fromPlatform();
      release = 'recall@${info.version}+${info.buildNumber}';
    } catch (_) {
      // Keep the pubspec-aligned fallback.
    }
  }
}

/// Thrown during app bootstrap when required configuration is missing, so
/// `main()` can render a clear error screen instead of a silent white screen.
class BootstrapException implements Exception {
  final String message;
  const BootstrapException(this.message);

  @override
  String toString() => 'BootstrapException: $message';
}
