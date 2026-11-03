import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access + refresh token. Lives in the phone's Keychain / Keystore, so closing the app does not sign you out.
class Session {
  const Session({
    required this.access,
    required this.refresh,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> j) => Session(
    access: j['access'] as String,
    refresh: j['refresh'] as String,
    expiresAt: (j['expiresAt'] as num).toInt(),
  );

  final String access;
  final String refresh;

  /// Epoch ms.
  final int expiresAt;

  Map<String, dynamic> toJson() => {
    'access': access,
    'refresh': refresh,
    'expiresAt': expiresAt,
  };
}

/// The account id (Cognito `sub`) inside an access token; null if it cannot be read.
String? subOf(String token) {
  try {
    final body = base64Url.normalize(token.split('.')[1]);
    final sub = (jsonDecode(utf8.decode(base64Url.decode(body))) as Map)['sub'];
    return sub is String ? sub : null;
  } on Object {
    return null;
  }
}

/// Where the session is kept. An interface so tests can use an in-memory store.
abstract interface class SessionStore {
  Future<Session?> load();
  Future<void> save(Session? s);
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'findme.session';
  final FlutterSecureStorage _storage;

  @override
  Future<Session?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null
          ? null
          : Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null; // unreadable (e.g. restored backup on a new phone): sign in again
    }
  }

  @override
  Future<void> save(Session? s) => s == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: jsonEncode(s.toJson()));
}
