import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fix = Fix(
    at: DateTime.utc(2026, 11, 4, 3, 15, 42),
    lat: 10.77,
    lon: 106.70,
    acc: 12,
  );

  test('overlandBatch encodes lon,lat order and UTC timestamp', () {
    final b = overlandBatch([fix], 'android');
    final f = (b['locations'] as List).single as Map<String, dynamic>;
    expect(f['type'], 'Feature');
    final g = f['geometry'] as Map<String, dynamic>;
    expect(g['type'], 'Point');
    expect(g['coordinates'], [106.70, 10.77]);
    final p = f['properties'] as Map<String, dynamic>;
    expect(p['timestamp'], '2026-11-04T03:15:42.000Z');
    expect(p['horizontal_accuracy'], 12);
    expect(p['device_id'], 'android');
  });

  test('overlandBatch converts a local time to UTC', () {
    final local = Fix(at: fix.at.toLocal(), lat: 1, lon: 2, acc: 3);
    final f = (overlandBatch([local], 'iphone')['locations'] as List).single;
    expect(
      ((f as Map)['properties'] as Map)['timestamp'],
      '2026-11-04T03:15:42.000Z',
    );
  });

  test('Fix json round-trip', () {
    expect(Fix.fromJson(fix.toJson()), fix);
  });
}
