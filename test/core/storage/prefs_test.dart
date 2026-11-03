import 'dart:convert';

import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String jwt(Object payload) =>
    'h.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.s';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const mine = Track(
    points: [TrackPoint(105.78, 21.03, 1000)],
    stops: [Stop(lon: 1, lat: 2, start: 'a', end: 'b', seconds: 60)],
    last: LastPoint(lon: 105.78, lat: 21.03, ts: 'T'),
  );
  final friends = <String, FriendTrail>{
    'f': (points: const [TrackPoint(1, 2, 3, 8)], last: null),
  };

  test('subOf: the account id inside the access token (or null)', () {
    expect(subOf(jwt({'sub': 'abc-123'})), 'abc-123');
    expect(subOf('not a token'), isNull);
    expect(subOf(jwt({'sub': 1})), isNull);
  });

  test("today's trail comes back only for the same account and day", () async {
    final p = SharedPrefs();
    await p.writeToday('a', '2026-11-04', mine, friends);
    final got = await p.readToday('a', '2026-11-04');
    expect(got?.mine, mine);
    expect(got?.friends['f']?.points, const [TrackPoint(1, 2, 3, 8)]);
    expect(got?.friends['f']?.last, isNull);
    expect(
      await p.readToday('b', '2026-11-04'),
      isNull,
    ); // someone else on this phone
    expect(
      await p.readToday('a', '2026-11-05'),
      isNull,
    ); // a new day starts from scratch
  });

  test('sign-out forgets it; a broken entry is simply nothing', () async {
    final p = SharedPrefs();
    await p.writeToday('a', 'd', mine, friends);
    await p.clear();
    expect(await p.readToday('a', 'd'), isNull);
    SharedPreferences.setMockInitialValues({'findme.today': '{oops'});
    expect(await SharedPrefs().readToday('a', 'd'), isNull);
  });
}
