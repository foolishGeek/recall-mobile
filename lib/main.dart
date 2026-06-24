// Recall · entry point. Bootstrap order (sprint S02 §7 / [D-OBS-1]):
//   1. Initialize Supabase + register core singletons BEFORE runApp (no race;
//      a missing dart-define throws → clear ErrorApp, never a white screen).
//   2. Init Sentry (skipped gracefully when SENTRY_DSN is empty for local dev),
//      gated by analytics opt-in. SentryFlutter.init owns zone + error hooks when
//      DSN is set — do NOT wrap runApp in a separate runZonedGuarded (zone
//      mismatch with ensureInitialized).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/utils/app_env.dart';
import 'data/local/app_database.dart';
import 'data/local/local_store.dart';
import 'data/models/json_utils.dart';
import 'data/services/app_session_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/sync_service.dart';
import 'data/services/sync_status_service.dart';
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
  late final SupabaseService supabase;
  try {
    supabase = await SupabaseService.bootstrap();
    Get.put<SupabaseService>(supabase, permanent: true);
    Get.put<AuthService>(AuthService(supabase), permanent: true);
    Get.put<TierService>(TierService(), permanent: true);
    // Starts an app_sessions row on launch/sign-in, ends it on background.
    Get.put<AppSessionService>(AppSessionService(supabase), permanent: true);
  } on BootstrapException catch (e) {
    runApp(ErrorApp(message: e.message));
    return;
  }

  // 2. Sentry — skip gracefully when DSN is empty (local dev). The offline
  //    layer is registered inside the Sentry zone so a DB-open failure is
  //    captured (S05 §7) before falling back to network-only mode.
  if (AppEnv.sentryDsn.isEmpty) {
    await _bootstrapOffline(supabase);
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
    appRunner: () async {
      await _bootstrapOffline(supabase);
      runApp(const RecallApp());
    },
  );
}

/// Opens the Drift cache and registers the offline/sync singletons [D-OFF-1].
/// On DB-open failure the app degrades to a network-only [LocalStore] (disabled)
/// + a Sentry capture, staying usable online (S05 §7). Kicks an initial drain so
/// reviews queued in a previous session replay at launch.
Future<void> _bootstrapOffline(SupabaseService supabase) async {
  LocalStore localStore;
  try {
    final db = AppDatabase();
    await db.customSelect('SELECT 1').get(); // force lazy open to surface errors
    localStore = LocalStore(db);
  } catch (e, st) {
    await Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) => scope.setTag('feature', 'offline_cache'),
    );
    localStore = LocalStore(null);
  }

  Get.put<LocalStore>(localStore, permanent: true);
  final status = Get.put<SyncStatusService>(SyncStatusService(), permanent: true);
  final sync = Get.put<SyncService>(
    SyncService(supabase, localStore, status),
    permanent: true,
  );
  Get.put<ConnectivityService>(
    ConnectivityService(status, sync),
    permanent: true,
  );

  unawaited(sync.drain());
}
