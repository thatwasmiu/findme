import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ingest token and the account (Cognito `sub`) that saved it.
typedef IngestToken = ({String token, String sub});

/// The tracker's own settings: the ingest token (secret) and whether tracking is on (not secret).
abstract interface class TrackerStore {
  Future<IngestToken?> token();

  /// Trims [raw]; an empty token is refused with an [ArgumentError].
  Future<void> saveToken(String raw, String sub);
  Future<bool> enabled();
  Future<void> setEnabled({required bool on});
  Future<void> forget();
}

class SecureTrackerStore implements TrackerStore {
  SecureTrackerStore([FlutterSecureStorage? storage])
    : _secure = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'findme.ingest';

  /// A plain bool in the legacy SharedPreferences file: Android's boot receiver reads it natively as
  /// `flutter.findme.tracking` in `FlutterSharedPreferences`.
  static const _onKey = 'findme.tracking';

  final FlutterSecureStorage _secure;

  @override
  Future<IngestToken?> token() async {
    try {
      final raw = await _secure.read(key: _tokenKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (token: j['token'] as String, sub: j['sub'] as String);
    } on Object {
      return null; // unreadable (restored backup): paste it again
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
    await _secure.delete(key: _tokenKey);
    await (await SharedPreferences.getInstance()).remove(_onKey);
  }
}

final trackerStoreProvider = Provider<TrackerStore>(
  (_) => SecureTrackerStore(),
);
