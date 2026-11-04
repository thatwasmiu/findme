import 'package:findme/app.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/config/version.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/features/tracker/data/geolocator_source.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Find Me $appVersion');
  if (debugConsoleEnabled) DebugLog.instance.hookErrors();
  try {
    final cfg = AppConfig.fromEnvironment();
    runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(cfg),
          locationSourceProvider.overrideWithValue(GeolocatorSource()),
        ],
        child: const FindMeApp(),
      ),
    );
  } on StateError catch (e) {
    runApp(
      ConfigErrorApp(e.message),
    ); // missing config: say how to fix it instead of crashing
  }
}
