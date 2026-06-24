// Recall · entry point. Bootstrap order (sprint S02 §7 / [D-OBS-1]):
//   1. Initialize Supabase + register core singletons BEFORE runApp (no race;
//      a missing dart-define throws → clear ErrorApp, never a white screen).
//   2. Init Sentry (skipped gracefully when SENTRY_DSN is empty for local dev),
//      gated by analytics opt-in. SentryFlutter.init owns zone + error hooks when
//      DSN is set — do NOT wrap runApp in a separate runZonedGuarded (zone
//      mismatch with ensureInitialized).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/utils/app_env.dart';
import 'data/models/json_utils.dart';
import 'data/services/app_session_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/tier_service.dart';

void _wireModelParseWarnings() {
  onModelParseWarning = (message) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: 'enum.parse',
        level: SentryLevel.warning,
      ),
    );
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bootstrap Supabase + core singletons before anything else.
  try {
    final supabase = await SupabaseService.bootstrap();
    Get.put<SupabaseService>(supabase, permanent: true);
    Get.put<AuthService>(AuthService(supabase), permanent: true);
    Get.put<TierService>(TierService(), permanent: true);
    // Starts an app_sessions row on launch/sign-in, ends it on background.
    Get.put<AppSessionService>(AppSessionService(supabase), permanent: true);
  } on BootstrapException catch (e) {
    runApp(ErrorApp(message: e.message));
    return;
  }

  // 2. Sentry — skip gracefully when DSN is empty (local dev).
  if (AppEnv.sentryDsn.isEmpty) {
    runApp(const RecallApp());
    return;
  }

  _wireModelParseWarnings();

  await SentryFlutter.init(
    (o) {
      o.dsn = AppEnv.sentryDsn;
      o.environment = AppEnv.env;
      o.release = AppEnv.release;
      o.tracesSampleRate = AppEnv.isProd ? 0.05 : 0.2;
      // Privacy gate — drop events when the user has opted out.
      o.beforeSend = (event, hint) =>
          Get.find<AuthService>().analyticsOptIn ? event : null;
    },
    appRunner: () => runApp(const RecallApp()),
  );
}
