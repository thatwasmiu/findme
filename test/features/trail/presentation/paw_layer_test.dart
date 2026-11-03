import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/paw_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smaller paws when zoomed out', () {
    expect([18, 17, 16, 15, 14, 13, 12].map(pawSize).toList(), [
      14,
      14,
      11,
      11,
      8,
      8,
      6,
    ]);
  });

  test('samePoints: same length, first time, last time and place', () {
    const a = [TrackPoint(1, 1, 10), TrackPoint(2, 2, 20)];
    expect(
      samePoints(a, const [TrackPoint(1, 1, 10), TrackPoint(2, 2, 20)]),
      isTrue,
    );
    expect(
      samePoints(a, const [TrackPoint(1, 1, 10), TrackPoint(2, 3, 20)]),
      isFalse,
    );
    expect(
      samePoints(a, const [TrackPoint(1, 1, 10), TrackPoint(2, 2, 21)]),
      isFalse,
    );
    expect(samePoints(a, const [TrackPoint(1, 1, 10)]), isFalse);
    expect(samePoints(const [], const []), isTrue);
  });

  test('nearestPrint: the closest within 14 px, else null', () {
    const pts = [
      TrackPoint(0, 0, 1),
      TrackPoint(10, 0, 2),
      TrackPoint(30, 0, 3),
    ];
    Offset project(TrackPoint p) => Offset(p.lon, p.lat);
    expect(nearestPrint(pts, const Offset(12, 0), project), pts[1]);
    expect(nearestPrint(pts, const Offset(20, 20), project), isNull);
  });

  test('start point is stored with 4 decimals', () {
    expect(round4(105.12345), 105.1235);
    expect(round4(21.98766), 21.9877);
  });
}
