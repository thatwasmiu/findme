import 'dart:io';
import 'dart:typed_data';

import 'package:findme/features/widget/data/tile_cache.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = TileKey(16, 1, 1);
  const b = TileKey(16, 2, 2);
  const c = TileKey(16, 3, 3);
  final first = Uint8List.fromList([1]);
  final second = Uint8List.fromList([2]);

  late Directory dir;
  late DateTime now;
  late int fetches;
  late Uint8List? answer;
  late TileCache cache;

  Future<Uint8List?> fetch(TileKey _) async {
    fetches++;
    return answer;
  }

  TileCache make({int maxFiles = 200}) =>
      TileCache(dir, fetch, () => now, maxFiles: maxFiles);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tiles');
    now = DateTime(2026, 11, 9, 8);
    fetches = 0;
    answer = first;
    cache = make();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('a fresh cached tile is returned without fetching', () async {
    await cache.get(a);
    expect(await cache.get(a), first);
    expect(fetches, 1);
  });

  test('a tile older than 7 days is fetched again and replaced', () async {
    await cache.get(a);
    now = now.add(const Duration(days: 8));
    answer = second;
    expect(await cache.get(a), second);
    expect(fetches, 2);
  });

  test('an expired tile is returned when the fetch fails', () async {
    await cache.get(a);
    now = now.add(const Duration(days: 8));
    answer = null;
    expect(await cache.get(a), first);
  });

  test('a missing tile whose fetch fails returns null', () async {
    answer = null;
    expect(await cache.get(a), isNull);
  });

  test('a failed tile is not requested again for 5 minutes, then is', () async {
    answer = null;
    await cache.get(a);
    expect(fetches, 1);
    now = now.add(const Duration(minutes: 4));
    await cache.get(a);
    expect(fetches, 1);
    now = now.add(const Duration(minutes: 2));
    await cache.get(a);
    expect(fetches, 2);
  });

  test('over maxFiles, the oldest files go', () async {
    cache = make(maxFiles: 2);
    await cache.get(a);
    now = now.add(const Duration(minutes: 1));
    await cache.get(b);
    now = now.add(const Duration(minutes: 1));
    await cache.get(c);
    expect(File('${dir.path}/16_1_1.png').existsSync(), isFalse);
    expect(File('${dir.path}/16_3_3.png').existsSync(), isTrue);
  });
}
