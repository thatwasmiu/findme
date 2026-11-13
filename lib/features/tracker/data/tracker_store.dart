import 'dart:convert';

import 'package:findme/core/storage/secure.dart';
import 'package:findme/features/tracker/domain/trip.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart' as policy;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ingest token and the account (Cognito `sub`) that saved it.
typedef IngestToken = ({String token, String sub});

/// The tracker's own settings: the ingest token (secret) and whether tracking is on (not secret).
/// The Keychain could not be read (an iPhone locked since it was turned on). Not the same as "no token": nothing
/// should ask the server for a new one because of it.
class StorageUnreadable implements Exception {
  const StorageUnreadable();
}

abstract interface class TrackerStore {
  Future<IngestToken?> token();

  /// Trims [raw]; an empty token is refused with an [ArgumentError].
  Future<void> saveToken(String raw, String sub);
  Future<bool> enabled();
  Future<void> setEnabled({required bool on});
  Future<void> forget();

  /// The account (Cognito `sub`) this phone's tracking belongs to: the token's, else whoever switched it on.
  Future<String?> owner();
  Future<void> setOwner(String sub);

  /// iPhone's blue "using location" indicator while tracking. A phone setting: [forget] keeps it.
  Future<bool> indicator();
  Future<void> setIndicator({required bool on});

  /// How long fixes may wait before an upload (50 waiting still go at once). A phone setting: [forget] keeps it.
  Future<Duration> uploadEvery();
  Future<void> setUploadEvery(Duration d);

  /// The account's sharing mode as the server last said: 'always', 'trip', or null (not known yet). Android's tile
  /// and widget read it natively (`flutter.findme.sharing`) to offer the trip button only in trip mode.
  Future<String?> sharingMode();
  Future<void> setSharingMode(String? mode);

  /// When the running trip stops by itself; null = no end (an open trip, or no trip). Read natively by the tile
  /// (`flutter.findme.tripUntil`, epoch ms).
  Future<DateTime?> tripUntil();
  Future<void> setTripUntil(DateTime? at);

  /// The preset the tile and the widget start with ("1 giờ" the first time). A phone setting: [forget] keeps it.
  Future<TripPreset> lastPreset();
  Future<void> setLastPreset(TripPreset p);

  /// A trip start (its preset key) or `'end'` that could not reach the server yet.
  Future<String?> tripPending();
  Future<void> setTripPending(String? p);
}

class SecureTrackerStore implements TrackerStore {
  SecureTrackerStore([FlutterSecureStorage? storage])
    : _secure = storage ?? backgroundSafeStorage;

  @visibleForTesting
  FlutterSecureStorage get storage => _secure;

  /// Read once, then kept: a locked phone's Keychain is never needed again while the app runs.
  IngestToken? _cached;

  static const _tokenKey = 'findme.ingest';

  /// A plain bool in the legacy SharedPreferences file: Android's boot receiver reads it natively as
  /// `flutter.findme.tracking` in `FlutterSharedPreferences`.
  static const _onKey = 'findme.tracking';
  static const _ownerKey = 'findme.trackerOwner';
  static const _indicatorKey = 'findme.trackerIndicator';
  static const _everyKey = 'findme.trackerUploadSeconds';
  static const _sharingKey = 'findme.sharing';
  static const _untilKey = 'findme.tripUntil';
  static const _presetKey = 'findme.tripPreset';
  static const _pendingKey = 'findme.tripPending';

  final FlutterSecureStorage _secure;

  @override
  Future<IngestToken?> token() async {
    if (_cached != null) return _cached;
    final String? raw;
    try {
      raw = await _secure.read(key: _tokenKey);
    } on PlatformException {
      throw const StorageUnreadable();
    }
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return _cached = (token: j['token'] as String, sub: j['sub'] as String);
    } on Object {
      return null; // garbled (restored backup): a new one is fetched
    }
  }

  @override
  Future<void> saveToken(String raw, String sub) async {
    final t = raw.trim();
    if (t.isEmpty) throw ArgumentError.value(raw, 'raw', 'empty token');
    await _secure.write(
      key: _tokenKey,
      value: jsonEncode({'token': t, 'sub': sub}),
    );
    _cached = (token: t, sub: sub);
  }

  @override
  Future<bool> enabled() async =>
      (await SharedPreferences.getInstance()).getBool(_onKey) ?? false;

  @override
  Future<void> setEnabled({required bool on}) async {
    await (await SharedPreferences.getInstance()).setBool(_onKey, on);
  }

  @override
  Future<void> forget() async {
    _cached = null;
    await _secure.delete(key: _tokenKey);
    final p = await SharedPreferences.getInstance();
    await p.remove(_onKey);
    await p.remove(_ownerKey);
    await p.remove(_sharingKey);
    await p.remove(_untilKey);
    await p.remove(_pendingKey);
  }

  static Future<void> _put(String key, String? v) async {
    final p = await SharedPreferences.getInstance();
    v == null ? await p.remove(key) : await p.setString(key, v);
  }

  @override
  Future<String?> sharingMode() async =>
      (await SharedPreferences.getInstance()).getString(_sharingKey);

  @override
  Future<void> setSharingMode(String? mode) => _put(_sharingKey, mode);

  @override
  Future<DateTime?> tripUntil() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_untilKey);
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> setTripUntil(DateTime? at) async {
    final p = await SharedPreferences.getInstance();
    at == null
        ? await p.remove(_untilKey)
        : await p.setInt(_untilKey, at.millisecondsSinceEpoch);
  }

  @override
  Future<TripPreset> lastPreset() async =>
      presetOf((await SharedPreferences.getInstance()).getString(_presetKey)) ??
      TripPreset.h1;

  @override
  Future<void> setLastPreset(TripPreset p) => _put(_presetKey, p.key);

  @override
  Future<String?> tripPending() async =>
      (await SharedPreferences.getInstance()).getString(_pendingKey);

  @override
  Future<void> setTripPending(String? p) => _put(_pendingKey, p);

  @override
  Future<String?> owner() async =>
      (await token())?.sub ??
      (await SharedPreferences.getInstance()).getString(_ownerKey);

  @override
  Future<bool> indicator() async =>
      (await SharedPreferences.getInstance()).getBool(_indicatorKey) ?? false;

  @override
  Future<void> setIndicator({required bool on}) async {
    await (await SharedPreferences.getInstance()).setBool(_indicatorKey, on);
  }

  @override
  Future<Duration> uploadEvery() async {
    final m = (await SharedPreferences.getInstance()).getInt(_everyKey);
    return m == null || m <= 0 ? policy.uploadEvery : Duration(seconds: m);
  }

  @override
  Future<void> setUploadEvery(Duration d) async {
    await (await SharedPreferences.getInstance()).setInt(
      _everyKey,
      d.inSeconds,
    );
  }

  @override
  Future<void> setOwner(String sub) async {
    await (await SharedPreferences.getInstance()).setString(_ownerKey, sub);
  }
}

final trackerStoreProvider = Provider<TrackerStore>(
  (_) => SecureTrackerStore(),
);
