// Recall · entry point. Bootstrap order (sprint S02 §7 / [D-OBS-1]):
//   1. Initialize Supabase + register core singletons BEFORE runApp (no race;
//      a missing dart-define throws → clear ErrorApp, never a white screen).
//   2. Init Sentry (skipped gracefully when SENTRY_DSN is empty for local dev),
//      gated by analytics opt-in. SentryFlutter.init owns zone + error hooks when
//      DSN is set — do NOT wrap runApp in a separate runZonedGuarded (zone
//      mismatch with ensureInitialized).

import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/config/limits_config.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/utils/app_env.dart';
import 'data/local/app_database.dart';
import 'data/local/local_store.dart';
import 'data/models/json_utils.dart';
import 'data/repositories/notification_repository.dart';
import 'data/services/app_session_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/play_update_service.dart';
import 'data/services/remote_config_service.dart';
import 'data/services/revenuecat_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/sync_service.dart';
import 'data/services/sync_status_service.dart';
import 'data/services/tier_service.dart';

/// FCM background/terminated handler (separate isolate — no GetX). Best-effort
/// `delivered` log for a Recall Drop; must never throw. [D-EF-10].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final data = message.data;
    if (data['type'] != 'recall_drop') return;
    final dedupeKey = data['dedupe_key'];
    if (dedupeKey is! String || dedupeKey.isEmpty) return;

    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await bootstrapFirebase();

    SupabaseService supabase;
    try {
      supabase = await SupabaseService.bootstrap();
    } catch (_) {
      // Already initialized in this isolate, or config missing.
      supabase = SupabaseService();
    }

    final userId = supabase.currentUserId;
    if (userId == null) return;

    await supabase.from('notification_events').upsert(
      {
        'user_id': userId,
        'type': 'delivered',
        'dedupe_key': dedupeKey,
        'metadata': const <String, dynamic>{},
      },
      onConflict: 'dedupe_key,type',
      ignoreDuplicates: true,
    );
  } catch (e, st) {
    // Best-effort: delivered logging must never crash the isolate. Surface to
    // Sentry if this isolate happens to have it wired; otherwise stay silent.
    try {
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'notifications_bg'),
      );
    } catch (_) {}
  }
}

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
  await AppEnv.hydrateRelease();

  // 1. Bootstrap Supabase + core singletons before anything else.
  late final SupabaseService supabase;
  try {
    supabase = await SupabaseService.bootstrap();
    Get.put<SupabaseService>(supabase, permanent: true);
    Get.put<AuthService>(AuthService(supabase), permanent: true);
    Get.put<TierService>(TierService(), permanent: true);
    Get.put<LimitsConfig>(LimitsConfig(), permanent: true);
    Get.put<PlayUpdateService>(PlayUpdateService(), permanent: true);
    Get.put<RemoteConfigService>(RemoteConfigService(), permanent: true);
    Get.put<AppSessionService>(AppSessionService(supabase), permanent: true);
    await bootstrapFirebase();
    if (isFirebaseReady) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      unawaited(Get.find<RemoteConfigService>().bootstrap());
    }
    // Eager, permanent: self-wires FCM streams + token refresh (mirrors
    // AppSessionService). Onboarding resolves this same instance.
    Get.put<NotificationService>(
      NotificationService(
        Get.find<AuthService>(),
        NotificationRepository(supabase),
      ),
      permanent: true,
    );

    // RevenueCat: configure the SDK once and keep the RC subscriber aligned with
    // the Supabase user (RC app_user_id = Supabase UUID) so webhook events
    // resolve to the right profile. Best-effort — a store/SDK hiccup must never
    // block boot (the paywall degrades to "Price unavailable").
    final revenueCat = Get.put<RevenueCatService>(
      RevenueCatService(),
      permanent: true,
    );
    final auth = Get.find<AuthService>();
    try {
      await revenueCat.configure();
      final initialUserId = auth.currentUserId;
      if (initialUserId != null) unawaited(revenueCat.logIn(initialUserId));
    } catch (_) {
      // Swallow: RevenueCat is non-essential to app launch.
    }
    ever(auth.sessionRx, (_) {
      final userId = auth.currentUserId;
      if (userId != null) {
        revenueCat.logIn(userId).catchError((_) {});
      } else {
        revenueCat.logOut().catchError((_) {});
      }
    });
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
