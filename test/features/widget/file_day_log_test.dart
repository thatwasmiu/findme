import 'dart:io';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/widget/data/file_day_log.dart';
import 'package:flutter_test/flutter_test.dart';

Fix fix(DateTime at, [double lat = 21]) =>
    Fix(at: at, lat: lat, lon: 105.8, acc: 5);

void main() {
  late Directory dir;
  late FileDayLog log;
  final morning = DateTime(2026, 11, 9, 8);
  final noon = DateTime(2026, 11, 9, 12);
  final tomorrow = DateTime(2026, 11, 10, 9);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('daylog');
    log = FileDayLog(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test("read returns today's fixes in order and the last one", () async {
    final a = fix(morning);
    final b = fix(noon);
    await log.append(a);
    await log.append(b);
    final t = await log.read(noon);
    expect(t.today, [a, b]);
    expect(t.last, b);
  });

  test(
    "read the next day: today is empty, last is still yesterday's last fix",
    () async {
      final b = fix(noon);
      await log.append(b);
      final t = await log.read(tomorrow);
      expect(t.today, isEmpty);
      expect(t.last, b);
    },
  );

  test("append on a new day drops the old day's lines from the file", () async {
    await log.append(fix(noon));
    final c = fix(tomorrow);
    await log.append(c);
    final lines = File('${dir.path}/day.jsonl')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toList();
    expect(lines, hasLength(1));
    expect((await log.read(tomorrow)).today, [c]);
  });

  test('a half-written last line is skipped', () async {
    final a = fix(morning);
    await log.append(a);
    File('${dir.path}/day.jsonl')
        .writeAsStringSync('{"t":"20', mode: FileMode.append);
    expect((await log.read(noon)).today, [a]);
  });

  test('a fix written after a half-written line is kept', () async {
    await log.append(fix(morning));
    File('${dir.path}/day.jsonl')
        .writeAsStringSync('{"t":"20', mode: FileMode.append);
    final b = fix(noon);
    await log.append(b);
    expect((await log.read(noon)).today, contains(b));
  });

  test('clear removes everything: today empty, last null', () async {
    await log.append(fix(noon));
    await log.clear();
    final t = await log.read(noon);
    expect(t.today, isEmpty);
    expect(t.last, isNull);
  });
}
