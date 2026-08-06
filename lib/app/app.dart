// Recall · root app. GetMaterialApp wired to the theme, route table, and the
// (already-registered) app-wide singletons. ErrorApp is the bootstrap-failure
// fallback so a missing config never shows a silent white screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/theme/recall_colors.dart';
import '../core/theme/recall_motion.dart';
import '../core/theme/recall_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Recall',
      debugShowCheckedModeBanner: false,
      theme: RecallTheme.light(),
      darkTheme: RecallTheme.dark(),
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: RecallMotion.normal,
      builder: (context, child) =>
          _SystemBars(child: child ?? const SizedBox()),
    );
  }
}

/// Edge-to-edge draws the canvas behind the status and navigation bars, so the
/// system icons have to be tinted against Recall's canvas rather than left to
/// the platform default (white icons, invisible on the light paper canvas).
class _SystemBars extends StatelessWidget {
  final Widget child;
  const _SystemBars({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icons = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: icons,
        // Without this, 3-button navigation gets a translucent scrim over the
        // canvas instead of a clean transparent bar.
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}

/// Shown when bootstrap fails (e.g. missing dart-defines). Standalone — does not
/// depend on GetX or the theme extensions being registered.
class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    const c = RecallColors.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: c.canvas,
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: c.ink, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Couldn’t start Recall',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.grey600, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
