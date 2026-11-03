import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TrackPoint reads the wire format [lon, lat, epochSec, acc|null]', () {
    final p = TrackPoint.fromJson(const [105.8, 21.0, 1700000000, null]);
    expect(p.lon, 105.8);
    expect(p.lat, 21.0);
    expect(p.t, 1700000000);
    expect(p.acc, isNull);
    expect(
      TrackPoint.fromJson(const [105, 21, 1, 12.5]),
      const TrackPoint(105, 21, 1, 12.5),
    );
  });

  test('Stop and LastPoint parse the /track JSON', () {
    final s = Stop.fromJson(const {
      'lon': 105.78,
      'lat': 21.03,
      'start': '2026-10-27T01:00:00.000Z',
      'end': '2026-10-27T02:00:00.000Z',
      'seconds': 3600,
      'name': null,
    });
    expect(s.name, isNull);
    expect(s.startAt, DateTime.utc(2026, 10, 27, 1));
    expect(s.endAt, DateTime.utc(2026, 10, 27, 2));
    final l = LastPoint.fromJson(const {
      'lon': 1,
      'lat': 2,
      'ts': '2026-10-27T01:00:00Z',
    });
    expect(l.lat, 2.0);
  });
}
