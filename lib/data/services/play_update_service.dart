// Recall · Google Play in-app updates. Force → immediate; soft → flexible.
// Sideload / Play Core unavailable → open store listing for this package id.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayUpdateService {
  Future<void> startUpdate({required bool force}) async {
    if (kIsWeb || !Platform.isAndroid) {
      await _openStoreListing();
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        await _openStoreListing();
        return;
      }

      if (force) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[play_update] $e');
      await _openStoreListing();
    }
  }

  Future<void> _openStoreListing() async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=${info.packageName}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
