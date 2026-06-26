// Recall · ThemeService. Owns the live ThemeMode for the 3-way appearance
// control (System / Light / Dark). The choice is cached locally (so it applies
// on cold start before the server profile loads) and reconciled with the server
// truth `profiles.theme` on Settings load [S24]. Runtime swap is via
// Get.changeThemeMode against the light/dark themes wired in app.dart.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/local_store.dart';

/// Canonical theme selection values (mirror the `profiles.theme` CHECK).
const String kThemeSystem = 'system';
const String kThemeLight = 'light';
const String kThemeDark = 'dark';

class ThemeService extends GetxService {
  ThemeService(this._local);

  final LocalStore _local;

  /// The active selection ('system' | 'light' | 'dark').
  String _current = kThemeSystem;
  String get current => _current;

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  /// Applies the locally cached choice on boot (post-frame so the app is built
  /// before we switch). Users on 'system' (the default) see no change.
  Future<void> _restore() async {
    final cached = await _local.cachedTheme();
    if (cached == null) return;
    _current = cached;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.changeThemeMode(_modeFor(cached)),
    );
  }

  /// Persists the choice locally and switches the live ThemeMode immediately.
  /// The server write (`profiles.theme`) is owned by the caller so it can revert
  /// on failure. Safe to call with the value already active (no-op-ish).
  Future<void> apply(String value) async {
    _current = value;
    await _local.setCachedTheme(value);
    Get.changeThemeMode(_modeFor(value));
  }

  static ThemeMode _modeFor(String value) {
    switch (value) {
      case kThemeLight:
        return ThemeMode.light;
      case kThemeDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
