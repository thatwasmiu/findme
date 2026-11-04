import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Tracking without any screen: Android's `BootReceiver` runs the Dart entrypoint `trackerBoot` (in `main.dart`)
/// after a reboot, which calls this. The container is never disposed: it lives as long as the engine does.
Future<ProviderContainer> startTrackerHeadless(List<Override> overrides) async {
  final c = ProviderContainer(overrides: overrides);
  await c.read(trackerControllerProvider.notifier).resume();
  return c;
}
