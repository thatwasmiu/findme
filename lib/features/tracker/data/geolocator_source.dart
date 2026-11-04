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
    // Already "all the time": asking again is pointless, and geolocator_android 5.2.1 would answer whileInUse
    // (it re-asks only FINE/COARSE, and reads "no background in the answer" as no background).
    if (await Geolocator.checkPermission() == LocationPermission.always) {
      return LocationAccess.always;
    }
    // The second ask is the "always" step (iOS, Android 10). Android 11+ answers whileInUse: the user has to pick
    // "Allow all the time" in settings, which the tracker sheet sends them to.
    if (await Geolocator.requestPermission() == LocationPermission.whileInUse) {
      await Geolocator.requestPermission();
    }
    // What the phone now has decides, not what a request answered.
    return _map(await Geolocator.checkPermission());
  }

  @override
  Stream<Fix> fixes({bool indicator = false}) =>
      Geolocator.getPositionStream(locationSettings: _settings(indicator))
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

  static LocationSettings _settings(bool indicator) =>
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.medium, // kCLLocationAccuracyHundredMeters
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: indicator,
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
