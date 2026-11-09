import 'dart:convert';
import 'dart:io';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/widget/domain/day_log.dart';

/// Today's fixes in `day.jsonl`, one per line, and the latest fix of any day in `last.json`.
class FileDayLog implements DayLog {
  FileDayLog(this._dir)
    : _day = File('${_dir.path}/day.jsonl'),
      _last = File('${_dir.path}/last.json'),
      _tmp = File('${_dir.path}/last.json.tmp');

  final Directory _dir;
  final File _day;
  final File _last;
  final File _tmp;

  /// Every operation waits for the one before it.
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final run = _tail.then((_) => op());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  @override
  Future<void> append(Fix f) => _serial(() async {
    await _dir.create(recursive: true);
    final previous = await _readLast();
    if (previous != null &&
        !sameLocalDay(previous.at, f.at) &&
        _day.existsSync()) {
      await _day.delete();
    }
    final line = jsonEncode(f.toJson());
    // The leading newline keeps a line cut off by a crash from swallowing this one; blank lines are skipped.
    await _day.writeAsString('\n$line\n', mode: FileMode.append, flush: true);
    await _tmp.writeAsString(line, flush: true);
    await _tmp.rename(_last.path);
  });

  @override
  Future<DayTrail> read(DateTime now) => _serial(() async {
    final today = <Fix>[];
    if (_day.existsSync()) {
      for (final line in await _day.readAsLines()) {
        final f = _parse(line);
        if (f != null && sameLocalDay(f.at, now)) today.add(f);
      }
    }
    return DayTrail(today: today, last: await _readLast());
  });

  @override
  Future<void> clear() => _serial(() async {
    for (final f in [_day, _last, _tmp]) {
      if (f.existsSync()) await f.delete();
    }
  });

  Future<Fix?> _readLast() async =>
      _last.existsSync() ? _parse(await _last.readAsString()) : null;

  static Fix? _parse(String line) {
    if (line.trim().isEmpty) return null;
    try {
      return Fix.fromJson(jsonDecode(line) as Map<String, dynamic>);
    } on Object {
      return null; // cut off by a crash
    }
  }
}
