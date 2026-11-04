import 'package:findme/features/tracker/data/geolocator_source.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// The platform side as Android really answers: [granted] is what the phone has; [requestAnswers] what each
/// requestPermission() returns (geolocator_android 5.2.1 says whileInUse when "all the time" was already granted).
class FakeGeolocator extends GeolocatorPlatform {
  FakeGeolocator(this.granted, this.requestAnswers);

  LocationPermission granted;
  final List<LocationPermission> requestAnswers;
  int requests = 0;

  @override
  Future<LocationPermission> checkPermission() async => granted;

  @override
  Future<LocationPermission> requestPermission() async {
    final a = requestAnswers[requests.clamp(0, requestAnswers.length - 1)];
    requests++;
    return a;
  }
}

void main() {
  test('already "all the time": always, without asking again', () async {
    final g = FakeGeolocator(LocationPermission.always, [
      LocationPermission.whileInUse,
    ]);
    GeolocatorPlatform.instance = g;
    expect(await GeolocatorSource().request(), LocationAccess.always);
    expect(g.requests, 0);
  });

  test('the phone, not the request answer, decides', () async {
    final g = FakeGeolocator(LocationPermission.denied, [
      LocationPermission.whileInUse,
    ]);
    GeolocatorPlatform.instance = g;
    // The user picks "all the time" in the second prompt, but the answer still says whileInUse.
    final r = GeolocatorSource().request().then((r) => r);
    g.granted = LocationPermission.always;
    expect(await r, LocationAccess.always);
  });

  test('only while using: whileInUse after asking twice', () async {
    final g = FakeGeolocator(LocationPermission.denied, [
      LocationPermission.whileInUse,
    ]);
    GeolocatorPlatform.instance = g;
    final r = GeolocatorSource().request();
    g.granted = LocationPermission.whileInUse;
    expect(await r, LocationAccess.whileInUse);
    expect(g.requests, 2);
  });
}
