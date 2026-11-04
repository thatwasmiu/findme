import 'dart:convert';
import 'dart:io';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Fixes waiting for the server, oldest first, one JSON line each in `queue.jsonl`. Nothing is removed until the
/// server said ok ([commit]); a batch the server refuses as malformed goes to `rejected.jsonl` ([reject]).
// ponytail: JSON-lines file, whole-file rewrite on commit; sqlite if queues of 100k+ points get slow.
class PointQueue {
  PointQueue(Directory dir)
    : _file = File('${dir.path}/queue.jsonl'),
      _rejected = File('${dir.path}/rejected.jsonl'),
      _tmp = File('${dir.path}/queue.jsonl.tmp');

  final File _file;
  final File _rejected;
  final File _tmp;

  /// Every operation waits for the one before it: two writes never overlap.
  Future<void> _last = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final run = _last.then((_) => op());
    _last = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<void> append(Fix f) => _serial(() async {
    // A line cut off by a crash must not swallow the next fix.
    final broken = await _endsMidLine(_file);
    await _file.writeAsString(
      '${broken ? '\n' : ''}${jsonEncode(f.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  });

  Future<List<Fix>> peek(int max) =>
      _serial(() async => (await _read(_file)).take(max).toList());

  Future<void> commit(int n) => _serial(() => _drop(n));

  Future<void> reject(int n) => _serial(() async {
    final moved = (await _read(_file)).take(n);
    await _rejected.writeAsString(
      moved.map((f) => '${jsonEncode(f.toJson())}\n').join(),
      mode: FileMode.append,
      flush: true,
    );
    await _drop(n);
  });

  Future<int> count() => _serial(() async => (await _read(_file)).length);

  Future<int> rejectedCount() =>
      _serial(() async => (await _read(_rejected)).length);

  Future<void> clear() => _serial(() async {
    for (final f in [_file, _rejected, _tmp]) {
      if (f.existsSync()) await f.delete();
    }
  });

  /// Rewrites the queue without its first [n] fixes: written to a temp file, then renamed over the queue, so a
  /// crash leaves either the old file or the new one, never half of one.
  Future<void> _drop(int n) async {
    final rest = (await _read(_file)).skip(n);
    await _tmp.writeAsString(
      rest.map((f) => '${jsonEncode(f.toJson())}\n').join(),
      flush: true,
    );
    await _tmp.rename(_file.path);
  }

  static Future<List<Fix>> _read(File f) async {
    if (!f.existsSync()) return const [];
    final out = <Fix>[];
    for (final line in await f.readAsLines()) {
      if (line.trim().isEmpty) continue;
      try {
        out.add(Fix.fromJson(jsonDecode(line) as Map<String, dynamic>));
      } on Object {
        // cut off by a crash: skip it, the rewrite drops it
      }
    }
    return out;
  }

  static Future<bool> _endsMidLine(File f) async {
    if (!f.existsSync()) return false;
    final r = await f.open();
    try {
      final len = await r.length();
      if (len == 0) return false;
      await r.setPosition(len - 1);
      return (await r.read(1)).first != 0x0A;
    } finally {
      await r.close();
    }
  }
}

final pointQueueProvider = FutureProvider<PointQueue>((_) async {
  final dir = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/tracker',
  );
  await dir.create(recursive: true);
  return PointQueue(dir);
});
