import 'dart:ui' show Offset, Rect;

import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tilesFor at 0,0 covers the four tiles around the centre', () {
    expect(tilesFor(0, 0).map((k) => k.x).toSet(), {32767, 32768});
    expect(tilesFor(0, 0).map((k) => k.y).toSet(), {32767, 32768});
    expect(tilesFor(0, 0).every((k) => k.z == 16), isTrue);
  });

  test('the centre lands in the middle of the image', () {
    expect(
      toImage(21.03, 105.85, centreLat: 21.03, centreLon: 105.85),
      const Offset(200, 200),
    );
  });

  test('east is right and north is up', () {
    final p = toImage(21.04, 105.86, centreLat: 21.03, centreLon: 105.85);
    expect(p.dx, greaterThan(200));
    expect(p.dy, lessThan(200));
  });

  test('tileRect at 0,0 puts tile 32768,32768 from the image centre', () {
    expect(
      tileRect(const TileKey(16, 32768, 32768), centreLat: 0, centreLon: 0),
      const Rect.fromLTWH(200, 200, 256, 256),
    );
  });
}
