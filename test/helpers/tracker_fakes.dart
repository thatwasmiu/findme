import 'dart:async';
import 'dart:convert';

import 'package:findme/features/tracker/data/ingest_client.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockIngest extends Mock implements IngestClient;

/// A Cognito-shaped access token whose payload says `sub`.
String jwt(String sub) {
  final body = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  return 'h.${body.replaceAll('=', '')}.s';
}

class MemoryTrackerStore implements TrackerStore {
  IngestToken? saved;
  bool on = false;
  int forgets = 0;

  @override
  Future<IngestToken?> token() async => saved;
  @override
  Future<void> saveToken(String raw, String sub) async {
    if (raw.trim().isEmpty) throw ArgumentError.value(raw);
    saved = (token: raw.trim(), sub: sub);
  }

  @override
  Future<bool> enabled() async => on;
  @override
  Future<void> setEnabled({required bool on}) async => this.on = on;
  @override
  Future<void> forget() async {
    forgets++;
    saved = null;
    on = false;
  }
}

/// GPS driven by hand: [emit] a fix, set [granted].
class FakeLocation implements LocationSource {
  LocationAccess granted = LocationAccess.always;
  LocationAccess afterRequest = LocationAccess.always;
  final ctl = StreamController<Fix>.broadcast();
  int listens = 0;
  int settingsOpened = 0;

  bool get listening => ctl.hasListener;

  void emit(Fix f) => ctl.add(f);

  @override
  Future<LocationAccess> access() async => granted;
  @override
  Future<LocationAccess> request() async => granted = afterRequest;
  @override
  Stream<Fix> fixes() {
    listens++;
    return ctl.stream;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// The tracker as other features see it: counts [forget] calls, does nothing else.
class FakeTracker extends TrackerController {
  FakeTracker([this.initial = const TrackerState()]);
  final TrackerState initial;
  int forgets = 0;
  int resumes = 0;

  @override
  TrackerState build() => initial;
  @override
  Future<void> forget() async => forgets++;
  @override
  Future<void> resume() async => resumes++;
}
