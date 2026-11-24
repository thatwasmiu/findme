import 'dart:convert';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/live_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// About 1.11 m of latitude per 0.00001°.
Fix at(double northM, {double acc = 5}) => Fix(
  at: DateTime.utc(2026, 11, 24, 8),
  lat: 10.77 + northM / 111195,
  lon: 106.7,
  acc: acc,
);

void main() {
  test('the first good fix is worth sending; a rough one never is', () {
    expect(worthPublishing(at(0), null), isTrue);
    expect(worthPublishing(at(0, acc: 101), null), isFalse);
    expect(worthPublishing(at(0, acc: 100), null), isTrue);
  });

  test('needs max(5 m, acc / 2) from the last published fix', () {
    expect(worthPublishing(at(4.9), at(0)), isFalse);
    expect(worthPublishing(at(5.1), at(0)), isTrue);
    // acc 30: GPS jitter at a standstill is up to ~15 m
    expect(worthPublishing(at(14, acc: 30), at(0)), isFalse);
    expect(worthPublishing(at(16, acc: 30), at(0)), isTrue);
  });

  test('payload: exactly lat, lon, ts (whole seconds), acc; 6 decimals', () {
    final f = Fix(
      at: DateTime.utc(2026, 11, 24, 8, 0, 0, 750),
      lat: 10.123456789,
      lon: -106.987654321,
      acc: 12.345,
    );
    final s = livePayload(f);
    expect(jsonDecode(s), {
      'lat': 10.123457,
      'lon': -106.987654,
      'ts': DateTime.utc(2026, 11, 24, 8).millisecondsSinceEpoch ~/ 1000,
      'acc': 12.3,
    });
    expect(utf8.encode(s).length, lessThanOrEqualTo(256));
  });

  test('live topic is live/<account id>', () {
    expect(liveTopic('abc-1'), 'live/abc-1');
  });
}
