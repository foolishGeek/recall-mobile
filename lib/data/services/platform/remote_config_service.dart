// Recall · Firebase Remote Config for force/soft app update gates.
// Best-effort: never blocks boot; defaults keep the app usable offline.
//
// Single RC key: `app_update_config` (String = JSON object).
//
// Gate rules (build = PackageInfo.buildNumber):
//   force.enabled + build < force.version_code → force (blocks app)
//   soft.enabled  + build < soft.version_code  → soft (dismissible)
//   Force always overrides soft when both would match.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/utils/app_env.dart';

class AppUpdateCopy {
  final String title;
  final String versionLabel;
  final String description;
  final String cta;

  const AppUpdateCopy({
    required this.title,
    required this.versionLabel,
    required this.description,
    required this.cta,
  });
}

enum AppUpdateGate { none, soft, force }

/// One Remote Config string key holding the whole update gate payload.
const kAppUpdateConfigKey = 'app_update_config';

const _kDefaultJson = '''
{
  "force": {
    "enabled": false,
    "version_code": 1,
    "title": "Update required",
    "version_label": "New version",
    "description": "This version of Recall is no longer supported. Update to keep revising.",
    "cta": "Update now"
  },
  "soft": {
    "enabled": false,
    "version_code": 1,
    "title": "Update available",
    "version_label": "New version",
    "description": "A newer build is ready with fixes and polish. You can update now or keep going.",
    "cta": "Update"
  }
}
''';

class RemoteConfigService extends GetxService {
  FirebaseRemoteConfig? _rc;
  Map<String, dynamic> _cfg = _parseDefault();
  Future<void>? _boot;

  static Map<String, dynamic> _parseDefault() {
    return jsonDecode(_kDefaultJson) as Map<String, dynamic>;
  }

  /// Idempotent — splash and main can both call this safely.
  Future<void> bootstrap() {
    return _boot ??= _bootstrapOnce();
  }

  Future<void> _bootstrapOnce() async {
    if (!isFirebaseReady) {
      if (kDebugMode) {
        debugPrint('[remote_config] skip — Firebase not ready');
      }
      return;
    }
    try {
      final rc = FirebaseRemoteConfig.instance;
      // Staging/debug: always fetch fresh so RC publishes are testable immediately.
      // Prod: short throttle (not 1h) so a mid-day publish still lands within a session.
      final fetchInterval = (!AppEnv.isProd || kDebugMode)
          ? Duration.zero
          : const Duration(minutes: 15);
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: fetchInterval,
      ));
      await rc.setDefaults(<String, dynamic>{
        kAppUpdateConfigKey: _kDefaultJson,
      });
      final activated = await rc.fetchAndActivate().timeout(
        const Duration(seconds: 10),
      );
      _rc = rc;
      _cfg = _readConfig();
      if (kDebugMode || !AppEnv.isProd) {
        debugPrint(
          '[remote_config] activated=$activated '
          'raw=${rc.getString(kAppUpdateConfigKey).length}c '
          'force=${_boolForce}/$forceUpdateVersionCode '
          'soft=${_boolSoft}/$softUpdateVersionCode',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[remote_config] $e');
      _cfg = _parseDefault();
    }
  }

  Map<String, dynamic> _readConfig() {
    final raw = _rc?.getString(kAppUpdateConfigKey) ?? '';
    if (raw.trim().isEmpty) return _parseDefault();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (kDebugMode) debugPrint('[remote_config] bad JSON: $e');
    }
    return _parseDefault();
  }

  Map<String, dynamic> _forceMap() {
    final m = _cfg['force'];
    if (m is Map<String, dynamic>) return m;
    if (m is Map) return Map<String, dynamic>.from(m);
    return const {};
  }

  Map<String, dynamic> _softMap() {
    final m = _cfg['soft'];
    if (m is Map<String, dynamic>) return m;
    if (m is Map) return Map<String, dynamic>.from(m);
    return const {};
  }

  bool get _boolForce => _asBool(_forceMap()['enabled'], false);
  bool get _boolSoft => _asBool(_softMap()['enabled'], false);

  int get forceUpdateVersionCode => _asInt(_forceMap()['version_code'], 1);
  int get softUpdateVersionCode => _asInt(_softMap()['version_code'], 1);

  AppUpdateCopy forceCopy() {
    final m = _forceMap();
    return AppUpdateCopy(
      title: _asString(m['title'], 'Update required'),
      versionLabel: _asString(m['version_label'], 'New version'),
      description: _asString(
        m['description'],
        'This version of Recall is no longer supported. Update to keep revising.',
      ),
      cta: _asString(m['cta'], 'Update now'),
    );
  }

  AppUpdateCopy softCopy() {
    final m = _softMap();
    return AppUpdateCopy(
      title: _asString(m['title'], 'Update available'),
      versionLabel: _asString(m['version_label'], 'New version'),
      description: _asString(
        m['description'],
        'A newer build is ready with fixes and polish. You can update now or keep going.',
      ),
      cta: _asString(m['cta'], 'Update'),
    );
  }

  Future<AppUpdateGate> resolveGate() async {
    try {
      // Ensure fetch finished before deciding (splash awaits this path).
      await bootstrap();
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 0;

      AppUpdateGate gate = AppUpdateGate.none;
      if (_boolForce && build < forceUpdateVersionCode) {
        gate = AppUpdateGate.force;
      } else if (_boolSoft && build < softUpdateVersionCode) {
        gate = AppUpdateGate.soft;
      }

      if (kDebugMode || !AppEnv.isProd) {
        debugPrint(
          '[remote_config] build=$build gate=$gate '
          '(force $_boolForce <$forceUpdateVersionCode, '
          'soft $_boolSoft <$softUpdateVersionCode)',
        );
      }
      return gate;
    } catch (e) {
      if (kDebugMode) debugPrint('[remote_config] resolveGate $e');
    }
    return AppUpdateGate.none;
  }

  static bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic v, String fallback) {
    if (v is String && v.isNotEmpty) return v;
    return fallback;
  }
}
