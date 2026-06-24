// Recall · environment. Reads compile-time dart-defines (passed via
// --dart-define-from-file=config/<flavor>.json). See recall-backend/docs/DART-DEFINES.md.

class AppEnv {
  const AppEnv._();

  static const env = String.fromEnvironment('ENV', defaultValue: 'staging');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const revenueCatApiKey =
      String.fromEnvironment('REVENUECAT_API_KEY');

  /// Sentry release tag. Kept in sync with pubspec `version:` (S24 wires the
  /// real package_info read).
  static const release = 'recall@1.0.0+1';

  static bool get isProd => env == 'prod';

  /// True when the minimum keys needed to boot Supabase are present.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Thrown during app bootstrap when required configuration is missing, so
/// `main()` can render a clear error screen instead of a silent white screen.
class BootstrapException implements Exception {
  final String message;
  const BootstrapException(this.message);

  @override
  String toString() => 'BootstrapException: $message';
}
