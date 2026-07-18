// Recall · reusable "share as image" helper. Renders any widget to a crisp PNG
// off-screen, then hands it to the OS share sheet or saves it to the gallery.
// One place so every shareable surface (summaries today, more later) produces
// the same branded image with the same reliability.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class RecallShare {
  const RecallShare._();

  static final ScreenshotController _controller = ScreenshotController();

  /// Renders [card] to PNG bytes off-screen at [pixelRatio] (3.0 → retina-crisp).
  /// [card] must declare its own width (no Expanded/Flexible/scroll views at the
  /// root); it is measured, then captured at its intrinsic size.
  static Future<Uint8List> _capture(
    Widget card, {
    BuildContext? context,
    double pixelRatio = 3.0,
  }) {
    return _controller.captureFromLongWidget(
      card,
      context: context,
      pixelRatio: pixelRatio,
      delay: const Duration(milliseconds: 40),
    );
  }

  /// Captures [card] and opens the OS share sheet with the image attached, so it
  /// can be sent to any app that accepts an image.
  static Future<void> shareWidget({
    required Widget card,
    BuildContext? context,
    String fileName = 'recall-summary.png',
    double pixelRatio = 3.0,
  }) async {
    final bytes = await _capture(card, context: context, pixelRatio: pixelRatio);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png', name: fileName)],
    );
  }

  /// Captures [card] and saves it straight to the device gallery / Photos.
  /// Returns true on success; false if permission was denied or saving failed.
  static Future<bool> saveWidgetToGallery({
    required Widget card,
    BuildContext? context,
    String album = 'Recall',
    String name = 'recall-summary',
    double pixelRatio = 3.0,
  }) async {
    try {
      final bytes =
          await _capture(card, context: context, pixelRatio: pixelRatio);
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) return false;
      await Gal.putImageBytes(bytes, album: album, name: name);
      return true;
    } on GalException {
      return false;
    }
  }
}
