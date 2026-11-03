import 'dart:math';
import 'dart:ui';

import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TZ is Asia/Ho_Chi_Minh (tests assume it, like the web tests)', () {
    expect(DateTime.parse('2026-10-27T00:00:00Z').toLocal().hour, 7);
  });

  test('paw colour by local hour: morning peach, afternoon pink, '
      'evening coral, night lavender', () {
    int at(int h) =>
        DateTime.parse(
          '2026-10-27T${((h + 24 - 7) % 24).toString().padLeft(2, '0')}'
          ':00:00Z',
        ).millisecondsSinceEpoch ~/
        1000;
    expect([8, 14, 19, 23, 3].map((h) => pawColor(at(h))).toList(), const [
      Color(0xFFFB923C),
      Color(0xFFEC4899),
      Color(0xFFF43F5E),
      Color(0xFF8B5CF6),
      Color(0xFF8B5CF6),
    ]);
  });

  test('bearing: north 0, east pi/2', () {
    TrackPoint p(double lon, double lat) => TrackPoint(lon, lat, 0);
    expect(bearing(p(105, 21), p(105, 21.001)), closeTo(0, 1e-9));
    expect(bearing(p(105, 21), p(105.001, 21)), closeTo(pi / 2, 1e-9));
  });

  test('distanceM: ~111 m per 0.001 degree of latitude', () {
    expect(
      distanceM((lat: 21.0, lon: 105.0), (lat: 21.001, lon: 105.0)),
      closeTo(111.2, 0.5),
    );
  });

  test('friendColor: stable, varied, never one of your own paw colours', () {
    final ids = List.generate(40, (i) => 'sub-$i-${i * 7919}');
    expect(friendColor('abc'), friendColor('abc'));
    expect(ids.map(friendColor).toSet().length, greaterThanOrEqualTo(5));
    final mine = [0, 6, 12, 18, 23]
        .map(
          (h) => pawColor(
            DateTime(2026, 10, 29, h).millisecondsSinceEpoch ~/ 1000,
          ),
        )
        .toSet();
    expect(ids.any((id) => mine.contains(friendColor(id))), isFalse);
  });

  test('friendColor matches the web hash (same colour on web and app)', () {
    // JS: h = (h*31 + charCode) >>> 0 over 'abc' = 96354 → 96354 % 8 = 2.
    expect(friendColor('abc'), const Color(0xFF6366F1));
  });
}
