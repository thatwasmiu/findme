import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:flutter_test/flutter_test.dart';

String iso(int s) => DateTime.fromMillisecondsSinceEpoch(
  s * 1000,
  isUtc: true,
).toIso8601String();

Stop stopAt(int a, int b, {String? name, double lat = 0, double lon = 0}) =>
    Stop(
      lon: lon,
      lat: lat,
      start: iso(a),
      end: iso(b),
      seconds: b - a,
      name: name,
    );

void main() {
  group('timeline / topStops', () {
    int t(int hh, [int mm = 0]) =>
        DateTime.utc(2026, 10, 27, hh, mm).millisecondsSinceEpoch ~/ 1000;
    Stop stop(int a, int b, String? name, [double lat = 21.03]) =>
        stopAt(a, b, name: name, lat: lat, lon: 105.78);

    test(
      'stays with the moves between them (moves under 100 m are wobble)',
      () {
        final home = stop(t(1), t(2, 30), 'Nhà');
        final cafe = stop(t(3), t(5), 'Cafe', 21.06);
        final pts = [
          TrackPoint(105.78, 21.03, t(1), 5),
          TrackPoint(105.78, 21.03, t(2, 30), 5),
          TrackPoint(105.78, 21.04, t(2, 40), 5),
          TrackPoint(105.78, 21.05, t(2, 50), 5),
          TrackPoint(105.78, 21.06, t(3), 5),
          TrackPoint(105.78, 21.06, t(5), 5),
          TrackPoint(105.78, 21.0601, t(5, 5), 5), // 11 m: wobble, no move row
        ];
        final rows = timeline(pts, [cafe, home]);
        expect(rows.map((r) => r is StopEntry ? 'stop' : 'move').toList(), [
          'stop',
          'move',
          'stop',
        ]);
        final move = rows[1] as MoveEntry;
        expect(move.km, closeTo(1.11, 0.05));
        expect(move.start, t(2, 40));
      },
    );

    test('several days: one row per name with summed time', () {
      final out = topStops([
        stop(t(1), t(2), 'Nhà'),
        stop(t(3), t(3, 30), 'Cafe'),
        stop(t(4), t(6), 'Nhà'),
        stop(t(7), t(7, 10), null),
      ]);
      expect(out.map((s) => (s.name, s.seconds)).toList(), [
        ('Nhà', 3 * 3600),
        ('Cafe', 1800),
        (null, 600),
      ]);
    });
  });

  group('at (replay position)', () {
    const pts = [
      TrackPoint(105, 21, 1000),
      TrackPoint(106, 22, 2000),
      TrackPoint(107, 23, 4000),
    ];
    test('interpolates between prints and clamps to the ends', () {
      expect(at(pts, 0), (105.0, 21.0, 1000.0));
      expect(at(pts, 1.5), (106.5, 22.5, 3000.0));
      expect(at(pts, 2), (107.0, 23.0, 4000.0));
      expect(at(pts, 9), (107.0, 23.0, 4000.0));
      expect(at(pts, -1), (105.0, 21.0, 1000.0));
    });
  });

  group('replay together (by the clock)', () {
    const pts = [TrackPoint(105, 21, 1000), TrackPoint(106, 22, 2000)];
    test('togetherSpan: earliest to latest print of anyone; null alone', () {
      expect(
        togetherSpan(pts, const [
          [TrackPoint(1, 1, 500), TrackPoint(1, 1, 1500)],
        ]),
        (500, 2000),
      );
      expect(togetherSpan(pts, const [[], []]), isNull);
      expect(togetherSpan(pts, const []), isNull);
      expect(
        togetherSpan(const [], const [
          [TrackPoint(1, 1, 7)],
        ]),
        isNull,
      );
    });

    test('atTime: nobody before the first print, a line between prints, '
        'standing still after the last', () {
      expect(atTime(pts, 999), isNull);
      expect(atTime(pts, 1000), (105.0, 21.0));
      expect(atTime(pts, 1500), (105.5, 21.5));
      expect(atTime(pts, 5000), (106.0, 22.0));
      expect(atTime(const [], 1500), isNull);
    });
  });

  group('refresh only the newest part of a big range', () {
    final old = Track(
      points: const [
        TrackPoint(1, 1, 100),
        TrackPoint(2, 2, 200),
        TrackPoint(3, 3, 300),
      ],
      stops: [stopAt(100, 150), stopAt(250, 320)],
      last: LastPoint(lon: 3, lat: 3, ts: iso(300)),
    );

    test('keeps what came before `from`, replaces the rest with the tail', () {
      final tail = Track(
        points: const [TrackPoint(3, 3, 300), TrackPoint(4, 4, 400)],
        stops: [stopAt(250, 420)],
        last: LastPoint(lon: 4, lat: 4, ts: iso(400)),
      );
      expect(
        mergeTail(old, tail, iso(250)),
        Track(
          points: const [
            TrackPoint(1, 1, 100),
            TrackPoint(2, 2, 200),
            TrackPoint(3, 3, 300),
            TrackPoint(4, 4, 400),
          ],
          stops: [stopAt(100, 150), stopAt(250, 420)],
          last: tail.last,
        ),
      );
    });

    test('nothing new in the tail: keeps the last point seen', () {
      expect(mergeTail(old, Track.empty, iso(1000)).last, old.last);
    });
  });

  group('where the refresh window starts', () {
    const pts = [TrackPoint(1, 1, 10000), TrackPoint(2, 2, 20000)];
    String js(int s) =>
        isoMs(DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true));

    test('nothing loaded yet: the whole range', () {
      expect(tailFrom(Track.empty, js(0)), js(0));
    });
    test('still at the last stop: from its start', () {
      expect(
        tailFrom(Track(points: pts, stops: [stopAt(5000, 19500)]), js(0)),
        js(5000),
      );
    });
    test('moving since the last stop: 15 min before the last print, '
        'never before the range', () {
      expect(
        tailFrom(Track(points: pts, stops: [stopAt(5000, 6000)]), js(0)),
        js(20000 - 900),
      );
      expect(tailFrom(const Track(points: pts), js(19500)), js(19500));
    });
  });
}
