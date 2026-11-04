import 'dart:io';

import 'package:findme/features/tracker/data/point_queue.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_test/flutter_test.dart';

Fix fx(int s) => Fix(
  at: DateTime.utc(2026, 11, 4, 3, 0, s),
  lat: 10 + s / 1000,
  lon: 106,
  acc: 10,
);

void main() {
  late Directory dir;
  late PointQueue q;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('queue');
    q = PointQueue(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('append then peek returns in order', () async {
    for (final s in [1, 2, 3]) {
      await q.append(fx(s));
    }
    expect(await q.peek(10), [fx(1), fx(2), fx(3)]);
    expect(await q.peek(2), [fx(1), fx(2)]);
  });

  test('commit removes only the first n', () async {
    for (final s in [1, 2, 3]) {
      await q.append(fx(s));
    }
    await q.commit(2);
    expect(await q.count(), 1);
    expect(await q.peek(10), [fx(3)]);
  });

  test('reject moves n to rejected', () async {
    for (final s in [1, 2, 3]) {
      await q.append(fx(s));
    }
    await q.reject(2);
    expect(await q.rejectedCount(), 2);
    expect(await q.count(), 1);
  });

  test('commit after reopen', () async {
    for (final s in [1, 2, 3]) {
      await q.append(fx(s));
    }
    await q.commit(1);
    final again = PointQueue(dir);
    expect(await again.peek(10), [fx(2), fx(3)]);
  });

  test('partial last line skipped', () async {
    await q.append(fx(1));
    await q.append(fx(2));
    File('${dir.path}/queue.jsonl')
        .writeAsStringSync('{"t":"2026', mode: FileMode.append);
    expect(await q.count(), 2);
    expect((await q.peek(10)).length, 2);
    await q.append(
      fx(3),
    ); // after a broken line, new fixes still land on their own line
    expect(await q.peek(10), [fx(1), fx(2), fx(3)]);
  });

  test('leftover tmp file ignored', () async {
    await q.append(fx(1));
    File('${dir.path}/queue.jsonl.tmp').writeAsStringSync('garbage\n');
    expect(await PointQueue(dir).peek(10), [fx(1)]);
  });

  test('concurrent appends all land', () async {
    await Future.wait([for (var s = 0; s < 30; s++) q.append(fx(s))]);
    expect(await q.count(), 30);
  });

  test('clear empties both files', () async {
    await q.append(fx(1));
    await q.append(fx(2));
    await q.reject(1);
    await q.clear();
    expect(await q.count(), 0);
    expect(await q.rejectedCount(), 0);
  });
}
