import 'package:findme/app.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/config/version.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/features/tracker/boot.dart';
import 'package:findme/features/tracker/data/geolocator_source.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/widget/data/live_trail_widget.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

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
          trailWidgetProvider.overrideWithValue(
            liveTrailWidget(defaultTargetPlatform),
          ),
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

List<Override> _headless() => [
  appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
  locationSourceProvider.overrideWithValue(GeolocatorSource()),
  trailWidgetProvider.overrideWithValue(liveTrailWidget(defaultTargetPlatform)),
];

/// Run by Android's `BootReceiver` after a reboot when tracking was on: no screen, just the tracker.
@pragma('vm:entry-point')
Future<void> trackerBoot() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startTrackerHeadless(_headless());
}

/// Run by Android's `TripBridge` when the Quick Settings tile or the widget button is tapped and no engine runs:
/// the tracker, then the command (`toggle`: start with the last preset, or end).
@pragma('vm:entry-point')
Future<void> tripCommand(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final c = await startTrackerHeadless(_headless());
  if (args.isNotEmpty && args.first == 'toggle') {
    await c.read(trackerControllerProvider.notifier).toggleTrip();
  }
}
