import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// The phone's GPS, with Overland's recommended settings baked in: about 100 m wanted accuracy on iPhone (GPS
/// still answers, mostly 5-30 m), pause when still, and keep running with the app in the background.
class GeolocatorSource implements LocationSource {
  @override
  Future<LocationAccess> access() async =>
      _map(await Geolocator.checkPermission());

  @override
  Future<LocationAccess> request() async {
    var p = await Geolocator.requestPermission();
    // The second ask is the "always" step (iOS, Android 10). Android 11+ answers whileInUse: the user has to pick
    // "Allow all the time" in settings, which the tracker sheet sends them to.
    if (p == LocationPermission.whileInUse) {
      p = await Geolocator.requestPermission();
    }
    return _map(p);
  }

  @override
  Stream<Fix> fixes() =>
      Geolocator.getPositionStream(locationSettings: _settings())
          // Before a first fix some phones send 0,0 or a negative accuracy; the server would drop them anyway.
          .where(
            (p) => p.accuracy >= 0 && !(p.latitude == 0 && p.longitude == 0),
          )
          .map(
            (p) => Fix(
              at: p.timestamp.toUtc(),
              lat: p.latitude,
              lon: p.longitude,
              acc: p.accuracy,
            ),
          );

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();

  static LocationSettings _settings() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppleSettings(
      accuracy: LocationAccuracy.medium, // kCLLocationAccuracyHundredMeters
      distanceFilter: 10,
      pauseLocationUpdatesAutomatically: true,
    ),
    _ => AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 10),
      // POST_NOTIFICATIONS is not requested. ponytail: Android 13+ hides this notification until the user allows
      // notifications; the service still runs. Request it if users miss the notification.
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Find Me đang ghi hành trình',
        notificationText: 'Chạm để mở',
        notificationChannelName: 'Ghi hành trình',
        setOngoing: true,
      ),
    ),
  };

  static LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always => LocationAccess.always,
    LocationPermission.whileInUse => LocationAccess.whileInUse,
    _ => LocationAccess.denied,
  };
}
