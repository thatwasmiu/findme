import 'package:findme/features/tracker/domain/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 13, 10); // 17:00 in Vietnam

  test('presets: keys the server takes, labels from the spec', () {
    expect(TripPreset.values.map((p) => p.key), [
      '15m',
      '1h',
      'tonight',
      'open',
    ]);
    expect(TripPreset.values.map((p) => p.label), [
      '15 phút',
      '1 giờ',
      'đến tối nay',
      'đến khi tắt',
    ]);
    expect(presetOf('tonight'), TripPreset.tonight);
    expect(presetOf('x'), isNull);
    expect(presetOf(null), isNull);
  });

  test('localEnd: what the server would answer, for an offline start', () {
    expect(localEnd(TripPreset.m15, now), DateTime.utc(2026, 11, 13, 10, 15));
    expect(localEnd(TripPreset.h1, now), DateTime.utc(2026, 11, 13, 11));
    expect(
      localEnd(TripPreset.tonight, now),
      DateTime.utc(2026, 11, 13, 16, 59, 59),
    );
    // 23:30 Vietnam is still "today" there although UTC says the 13th 16:30
    expect(
      localEnd(TripPreset.tonight, DateTime.utc(2026, 11, 13, 16, 30)),
      DateTime.utc(2026, 11, 13, 16, 59, 59),
    );
    expect(localEnd(TripPreset.open, now), isNull);
  });

  test('tripOver: only past a set end', () {
    expect(tripOver(null, now), isFalse);
    expect(tripOver(now.add(const Duration(seconds: 1)), now), isFalse);
    expect(tripOver(now, now), isTrue);
  });

  test('tripLeft wording', () {
    expect(tripLeft(null, now), 'đến khi tắt');
    expect(tripLeft(now.add(const Duration(minutes: 42)), now), 'còn 42 phút');
    expect(
      tripLeft(now.add(const Duration(minutes: 41, seconds: 10)), now),
      'còn 42 phút',
    );
    expect(
      tripLeft(now.add(const Duration(hours: 1, minutes: 5)), now),
      'còn 1 giờ 5 phút',
    );
    expect(tripLeft(now.add(const Duration(hours: 2)), now), 'còn 2 giờ');
    expect(tripLeft(now, now), 'còn 0 phút');
  });

  test('sharingFromJson', () {
    expect(sharingFromJson({'name': 'A'}), isNull); // server without trip mode
    expect(sharingFromJson({'sharing': 'always', 'trip': false}), (
      tripMode: false,
      on: false,
      until: null,
    ));
    expect(
      sharingFromJson({
        'sharing': 'trip',
        'trip': true,
        'tripFrom': '2026-11-13T10:00:00.000Z',
        'tripUntil': '2026-11-13T11:00:00.000Z',
      }),
      (tripMode: true, on: true, until: DateTime.utc(2026, 11, 13, 11)),
    );
  });
}
