import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocationAccess { denied, whileInUse, always }

/// Where fixes come from: the phone's GPS (`GeolocatorSource`), or a fake in tests.
abstract interface class LocationSource {
  Future<LocationAccess> access();

  /// Asks the user; may return less than [LocationAccess.always] (Android 11+ only grants that in settings).
  Future<LocationAccess> request();

  /// Background-capable stream of fixes, until cancelled.
  Stream<Fix> fixes();
  Future<void> openSettings();
}

/// Overridden in `main.dart` with the real GPS; tests override it with a fake.
final locationSourceProvider = Provider<LocationSource>(
  (_) => throw UnimplementedError('override locationSourceProvider'),
);
