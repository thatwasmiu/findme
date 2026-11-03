import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret settings kept on this phone (the web's localStorage keys).
abstract interface class Prefs {
  /// The last point this device showed (lon, lat), or null.
  Future<(double, double)?> startPoint();
  Future<void> rememberStart(double lon, double lat);

  /// Which friends are shown on the map.
  Future<List<String>> shownFriends();
  Future<void> saveShownFriends(List<String> ids);

  /// Forget both (another account may sign in next).
  Future<void> clear();
}

class SharedPrefs implements Prefs {
  static const _start = 'findme:start';
  static const _shown = 'findme.shownFriends';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  @override
  Future<(double, double)?> startPoint() async {
    try {
      final v = jsonDecode((await _p).getString(_start) ?? 'null');
      if (v is List &&
          v.length == 2 &&
          v.every((n) => n is num && n.isFinite)) {
        return ((v[0] as num).toDouble(), (v[1] as num).toDouble());
      }
    } on Object {
      // bad value: fall through
    }
    return null;
  }

  @override
  Future<void> rememberStart(double lon, double lat) async {
    await (await _p).setString(_start, jsonEncode([round4(lon), round4(lat)]));
  }

  @override
  Future<List<String>> shownFriends() async =>
      (await _p).getStringList(_shown) ?? const [];

  @override
  Future<void> saveShownFriends(List<String> ids) async {
    await (await _p).setStringList(_shown, ids);
  }

  @override
  Future<void> clear() async {
    final p = await _p;
    await p.remove(_start);
    await p.remove(_shown);
  }
}

/// 4 decimals (~10 m), as the web stores it.
double round4(double v) => double.parse(v.toStringAsFixed(4));

final prefsProvider = Provider<Prefs>((_) => SharedPrefs());
