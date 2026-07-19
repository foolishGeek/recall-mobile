// Recall · Firebase Remote Config for force/soft app update gates.
// Best-effort: never blocks boot; defaults keep the app usable offline.
//
// Gate rules (build = PackageInfo.buildNumber):
//   force_update + build < force_update_version_code → force (blocks app)
//   soft_update  + build < soft_update_version_code  → soft (dismissible)
//   Force always overrides soft when both would match.

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/firebase/firebase_bootstrap.dart';

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

class RemoteConfigService extends GetxService {
  FirebaseRemoteConfig? _rc;
  bool _ready = false;

  static const _defaults = <String, dynamic>{
    // Numeric floors: show gate when installed build is *strictly below* these.
    'force_update_version_code': 1,
    'soft_update_version_code': 1,
    'force_update': false,
    'soft_update': false,
    'force_update_title': 'Update required',
    'force_update_version_label': 'New version',
    'force_update_description':
        'This version of Recall is no longer supported. Update to keep revising.',
    'force_update_cta': 'Update now',
    'soft_update_title': 'Update available',
    'soft_update_version_label': 'New version',
    'soft_update_description':
        'A newer build is ready with fixes and polish. You can update now or keep going.',
    'soft_update_cta': 'Update',
  };

  Future<void> bootstrap() async {
    if (!isFirebaseReady) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));
      await rc.setDefaults(_defaults);
      await rc.fetchAndActivate().timeout(const Duration(seconds: 10));
      _rc = rc;
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[remote_config] $e');
      _ready = false;
    }
  }

  bool get _boolForce => _getBool('force_update');
  bool get _boolSoft => _getBool('soft_update');

  /// Builds strictly below this are force-blocked when [force_update] is true.
  int get forceUpdateVersionCode => _getInt('force_update_version_code', 1);

  /// Builds strictly below this get a soft nudge when [soft_update] is true
  /// (and force did not already win).
  int get softUpdateVersionCode => _getInt('soft_update_version_code', 1);

  AppUpdateCopy forceCopy() => AppUpdateCopy(
        title: _getString('force_update_title', _defaults['force_update_title'] as String),
        versionLabel: _getString(
            'force_update_version_label',
            _defaults['force_update_version_label'] as String),
        description: _getString(
            'force_update_description',
            _defaults['force_update_description'] as String),
        cta: _getString('force_update_cta', _defaults['force_update_cta'] as String),
      );

  AppUpdateCopy softCopy() => AppUpdateCopy(
        title: _getString('soft_update_title', _defaults['soft_update_title'] as String),
        versionLabel: _getString(
            'soft_update_version_label',
            _defaults['soft_update_version_label'] as String),
        description: _getString(
            'soft_update_description',
            _defaults['soft_update_description'] as String),
        cta: _getString('soft_update_cta', _defaults['soft_update_cta'] as String),
      );

  Future<AppUpdateGate> resolveGate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 0;

      // Force overrides soft whenever the installed build is below the force floor.
      if (_boolForce && build < forceUpdateVersionCode) {
        return AppUpdateGate.force;
      }
      if (_boolSoft && build < softUpdateVersionCode) {
        return AppUpdateGate.soft;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[remote_config] resolveGate $e');
    }
    return AppUpdateGate.none;
  }

  bool _getBool(String key) {
    if (!_ready || _rc == null) return _defaults[key] as bool? ?? false;
    return _rc!.getBool(key);
  }

  int _getInt(String key, int fallback) {
    if (!_ready || _rc == null) return fallback;
    return _rc!.getInt(key);
  }

  String _getString(String key, String fallback) {
    if (!_ready || _rc == null) return fallback;
    final v = _rc!.getString(key);
    return v.isEmpty ? fallback : v;
  }
}
