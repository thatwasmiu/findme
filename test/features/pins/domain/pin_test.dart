import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

PinMedia item({String status = 'ready', String? thumb = 'a/thumb.webp'}) =>
    PinMedia(id: 'm', kind: 'image', status: status, thumb: thumb);

Pin pin(String id, double lat, double lon, [List<PinMedia>? media]) => Pin(
  id: id,
  lat: lat,
  lon: lon,
  createdAt: '2026-11-10T00:00:00.000Z',
  media: media ?? [item()],
);

void main() {
  // 10 m apart, well inside one 64 px cell at zoom 10.
  final a = pin('a', 10.7769, 106.7009, [item(), item()]);
  final b = pin('b', 10.7770, 106.7009);

  group('mergePins', () {
    test('two pins 10 m apart merge when zoomed out', () {
      final bubbles = mergePins([a, b], 10);
      expect(bubbles, hasLength(1));
      expect(bubbles.first.count, 3);
      expect(bubbles.first.pins.map((p) => p.id), ['a', 'b']);
      expect(bubbles.first.lat, closeTo(10.77695, 0.0001));
    });

    test('separate when zoomed in all the way', () {
      expect(mergePins([a, b], 19), hasLength(2));
    });

    test('far apart pins stay separate when zoomed out', () {
      expect(mergePins([a, pin('c', 21.03, 105.85)], 10), hasLength(2));
    });

    test('thumb is the first ready thumb, null while nothing is ready', () {
      final waiting = item(status: 'processing', thumb: null);
      expect(
        mergePins([
          pin('p', 1, 1, [waiting, item(thumb: 'b/thumb.webp')]),
        ], 10).first.thumb,
        'b/thumb.webp',
      );
      expect(
        mergePins([
          pin('p', 1, 1, [waiting]),
        ], 10).first.thumb,
        isNull,
      );
    });

    test('empty list', () => expect(mergePins([], 10), isEmpty));
  });

  group('startPosition', () {
    const geo = (lat: 1.0, lon: 1.0);
    const last = (lat: 2.0, lon: 2.0);
    const center = (lat: 3.0, lon: 3.0);
    test('prefers GPS', () => expect(startPosition(geo, last, center), geo));
    test(
      'then the latest point',
      () => expect(startPosition(null, last, center), last),
    );
    test(
      'then the map centre',
      () => expect(startPosition(null, null, center), center),
    );
  });

  group('nameNear', () {
    Stop stop(String? name, double lat, double lon) =>
        Stop(name: name, lat: lat, lon: lon, start: 'S', end: 'E', seconds: 60);

    test('nearest named stop within 100 m', () {
      expect(
        nameNear(
          [stop('Xa', 10.7775, 106.7), stop('Gần', 10.77705, 106.7)],
          10.777,
          106.7,
        ),
        'Gần',
      );
    });

    test('ignores unnamed and farther stops', () {
      expect(
        nameNear(
          [stop(null, 10.777, 106.7), stop('Xa', 10.79, 106.7)],
          10.777,
          106.7,
        ),
        '',
      );
    });
  });

  test('pinDate is day/month/year', () {
    expect(pinDate(DateTime(2026, 3, 9, 12).toIso8601String()), '9/3/2026');
  });

  test('Pin.fromJson reads whole-number coordinates and media', () {
    final p = Pin.fromJson({
      'id': 'a',
      'lat': 10,
      'lon': 106.5,
      'name': null,
      'note': 'n',
      'createdAt': 'T',
      'shareCode': null,
      'media': [
        {
          'id': 'm',
          'kind': 'video',
          'status': 'ready',
          'thumb': 't',
          'display': 'd',
          'hls': 'h',
        },
      ],
    });
    expect(p.lat, 10.0);
    expect(p.media.single.isVideo, isTrue);
    expect(p.media.single.hls, 'h');
  });
}
