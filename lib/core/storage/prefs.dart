import 'dart:convert';

import 'package:findme/features/trail/domain/models.dart';
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

  /// Today's trail (yours and your shown friends') kept on the phone, so opening the app draws it at once and the
  /// first request asks only for what came in since (the web's `todayCache.ts`). One entry, for one account ([who],
  /// the token's `sub`) and one local [day]; anything else reads as null.
  Future<TodayCache?> readToday(String who, String day);
  Future<void> writeToday(
    String who,
    String day,
    Track mine,
    Map<String, FriendTrail> friends,
  );
  Future<void> clearToday();

  /// Forget all of it (another account may sign in next).
  Future<void> clear();
}

typedef TodayCache = ({Track mine, Map<String, FriendTrail> friends});

class SharedPrefs implements Prefs {
  static const _start = 'findme:start';
  static const _shown = 'findme.shownFriends';
  static const _today = 'findme.today';

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
  Future<TodayCache?> readToday(String who, String day) async {
    try {
      final e = jsonDecode((await _p).getString(_today) ?? 'null');
      if (e is! Map<String, dynamic> || e['who'] != who || e['day'] != day) {
        return null;
      }
      final m = e['mine'] as Map<String, dynamic>;
      return (
        mine: Track(
          points: trackPointsFromJson(m['points']),
          stops: [
            for (final s in m['stops'] as List<dynamic>)
              Stop.fromJson(s as Map<String, dynamic>),
          ],
          last: _last(m['last']),
        ),
        friends: {
          for (final f in (e['friends'] as Map<String, dynamic>).entries)
            f.key: (
              points: trackPointsFromJson(
                (f.value as Map<String, dynamic>)['points'],
              ),
              last: _last((f.value as Map<String, dynamic>)['last']),
            ),
        },
      );
    } on Object {
      return null; // broken entry: simply no head start
    }
  }

  static LastPoint? _last(Object? j) =>
      j == null ? null : LastPoint.fromJson(j as Map<String, dynamic>);

  @override
  Future<void> writeToday(
    String who,
    String day,
    Track mine,
    Map<String, FriendTrail> friends,
  ) async {
    await (await _p).setString(
      _today,
      jsonEncode({
        'who': who,
        'day': day,
        'mine': {'points': mine.points, 'stops': mine.stops, 'last': mine.last},
        'friends': {
          for (final f in friends.entries)
            f.key: {'points': f.value.points, 'last': f.value.last},
        },
      }),
    );
  }

  @override
  Future<void> clearToday() async {
    await (await _p).remove(_today);
  }

  @override
  Future<void> clear() async {
    final p = await _p;
    await p.remove(_start);
    await p.remove(_shown);
    await p.remove(_today);
  }
}

/// 4 decimals (~10 m), as the web stores it.
double round4(double v) => double.parse(v.toStringAsFixed(4));

final prefsProvider = Provider<Prefs>((_) => SharedPrefs());
