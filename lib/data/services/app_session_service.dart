// Recall · AppSessionService. Logs an `app_sessions` row on launch/sign-in
// (platform + app_version) and stamps `ended_at` when the app backgrounds — the
// only server-side telemetry in v1 [D-OBS-2]. Offline failures are swallowed
// with a breadcrumb (a durable queue lands in S05).

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_env.dart';
import 'supabase_service.dart';

class AppSessionService extends GetxService with WidgetsBindingObserver {
  AppSessionService(this._supabase);

  final SupabaseService _supabase;
  StreamSubscription<AuthState>? _authSub;
  String? _sessionId;
  bool _busy = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    if (_supabase.currentUserId != null) {
      unawaited(_startSession());
    }
    _authSub = _supabase.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          unawaited(_startSession());
          break;
        case AuthChangeEvent.signedOut:
          unawaited(_endSession());
          break;
        default:
          break;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_endSession());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_startSession());
    }
  }

  Future<void> _startSession() async {
    if (_sessionId != null || _busy) return;
    final uid = _supabase.currentUserId;
    if (uid == null) return;

    _busy = true;
    try {
      final row = await _supabase
          .from('app_sessions')
          .insert({
            'user_id': uid,
            'platform': _platform(),
            'app_version': AppEnv.release,
          })
          .select('id')
          .single();
      _sessionId = row['id']?.toString();
    } catch (e) {
      _breadcrumb('start failed (queued S05): $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _endSession() async {
    final id = _sessionId;
    if (id == null) return;
    _sessionId = null;
    try {
      await _supabase.from('app_sessions').update(
        {'ended_at': DateTime.now().toUtc().toIso8601String()},
      ).eq('id', id);
    } catch (e) {
      _breadcrumb('end failed: $e');
    }
  }

  String _platform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return Platform.operatingSystem;
  }

  void _breadcrumb(String message) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'app_session $message',
        category: 'app_session',
        level: SentryLevel.info,
      ),
    );
  }

  @override
  void onClose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_endSession());
    super.onClose();
  }
}
