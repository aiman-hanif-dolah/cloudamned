import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_constants.dart';

/// Desktop window chrome (Windows / macOS / Linux).
class DesktopBootstrap {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
      minimumSize: Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      title: '${AppConstants.appName} — ${AppConstants.appTagline}',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
