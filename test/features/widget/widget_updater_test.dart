import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/widget/data/widget_updater.dart';
import 'package:findme/features/widget/domain/day_log.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:findme/features/widget/domain/widget_tiles.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryDays implements DayLog {
  final fixes = <Fix>[];
  bool failAppend = false;
  int clears = 0;

  @override
  Future<void> append(Fix f) async {
    if (failAppend) throw StateError('disk full');
    fixes.add(f);
  }

  @override
  Future<DayTrail> read(DateTime now) async => DayTrail(
    today: fixes.where((f) => sameLocalDay(f.at, now)).toList(),
    last: fixes.isEmpty ? null : fixes.last,
  );

  @override
  Future<void> clear() async {
    clears++;
    fixes.clear();
  }
}

class NoTiles implements WidgetTiles {
  @override
  Future<Uint8List?> get(TileKey key) async => null;
}

class CountingHost implements WidgetHost {
  int publishes = 0;
  int labels = 0;
  int clears = 0;
  DateTime? lastFix;
  bool failPublish = false;

  @override
  Future<void> publish(Uint8List png, DateTime last) async {
    if (failPublish) throw StateError('no space');
    publishes++;
    lastFix = last;
  }

  @override
  Future<void> refreshLabel() async => labels++;

  @override
  Future<void> clear() async => clears++;
}

void main() {
  final base = DateTime(2026, 11, 9, 8);
  const minute = Duration(minutes: 1);

  late MemoryDays days;
  late CountingHost host;
  late WidgetScene? scene;
  late bool failRender;
  Completer<Uint8List>? hold;

  Fix fix(DateTime at) => Fix(at: at, lat: 21, lon: 105.8, acc: 5);

  setUp(() {
    days = MemoryDays();
    host = CountingHost();
    scene = null;
    failRender = false;
    hold = null;
  });

  void run(
    void Function(FakeAsync async, WidgetUpdater u) body, {
    DateTime? start,
  }) {
    fakeAsync((async) {
      final origin = start ?? base;
      final parts = WidgetParts(
        days: days,
        tiles: NoTiles(),
        host: host,
        render: (s, _) async {
          scene = s;
          if (failRender) {
            failRender = false;
            throw StateError('no image');
          }
          return hold?.future ?? Future.value(Uint8List(0));
        },
      );
      final u = WidgetUpdater(
        () async => parts,
        () => origin.add(async.elapsed),
      );
      body(async, u);
      u.stop();
      async.flushMicrotasks();
    });
  }

  test('several fixes within a minute give one publish, at the minute end', () {
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      for (var i = 0; i < 3; i++) {
        u.onFix(fix(base.add(Duration(seconds: i * 10))));
        async.elapse(const Duration(seconds: 10));
      }
      expect(host.publishes, 0);
      async.elapse(const Duration(seconds: 30));
      expect(host.publishes, 1);
    });
  });

  test('the last fix of a burst is drawn although no more follow', () {
    run((async, u) {
      u.start();
      async.elapse(const Duration(seconds: 50));
      final last = fix(base.add(const Duration(seconds: 50)));
      u.onFix(last);
      async.elapse(const Duration(seconds: 10));
      expect(host.publishes, 1);
      expect(host.lastFix, last.at);
    });
  });

  test('a minute with no new fix refreshes the label only', () {
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      u.onFix(fix(base));
      async.elapse(minute);
      expect(host.publishes, 1);
      async.elapse(minute);
      expect(host.publishes, 1);
      expect(host.labels, 1);
    });
  });

  test('start publishes straight away when there is a last fix', () {
    days.fixes.add(fix(base));
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      expect(host.publishes, 1);
    });
  });

  test('refresh with nothing recorded publishes nothing', () {
    run((async, u) {
      unawaited(u.refresh());
      async.flushMicrotasks();
      expect(host.publishes, 0);
    });
  });

  test('crossing local midnight redraws with an empty trail, here = last', () {
    final evening = DateTime(2026, 11, 9, 23, 59, 30);
    final last = fix(evening.subtract(const Duration(minutes: 5)));
    days.fixes.add(last);
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      expect(host.publishes, 1);
      expect(scene!.trail, hasLength(1));
      async.elapse(minute);
      expect(host.publishes, 2);
      expect(scene!.trail, isEmpty);
      expect(scene!.here.lat, last.lat);
    }, start: evening);
  });

  test('stop ends the timer', () {
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      u.stop();
      async.elapse(const Duration(minutes: 5));
      expect(host.labels, 0);
    });
  });

  test('clear clears the host and the day', () {
    days.fixes.add(fix(base));
    run((async, u) {
      unawaited(u.clear());
      async.flushMicrotasks();
      expect(host.clears, 1);
      expect(days.fixes, isEmpty);
    });
  });

  test('a fix arriving after clear is ignored until start', () {
    run((async, u) {
      unawaited(u.clear());
      async.flushMicrotasks();
      u.onFix(fix(base));
      async.elapse(const Duration(minutes: 2));
      expect(days.fixes, isEmpty);
      expect(host.publishes, 0);
      u.start();
      u.onFix(fix(base));
      async.flushMicrotasks();
      expect(days.fixes, hasLength(1));
    });
  });

  test('a draw running during clear does not publish', () {
    days.fixes.add(fix(base));
    final held = hold = Completer<Uint8List>();
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      unawaited(u.clear());
      async.flushMicrotasks();
      held.complete(Uint8List(0));
      async.flushMicrotasks();
      expect(host.publishes, 0);
      expect(host.clears, 1);
    });
  });

  test('a failed publish does not stop clear', () {
    days.fixes.add(fix(base));
    host.failPublish = true;
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      unawaited(u.clear());
      async.flushMicrotasks();
      expect(host.clears, 1);
      expect(days.fixes, isEmpty);
    });
  });

  test('render throwing once: the next minute tries again and publishes', () {
    days.fixes.add(fix(base));
    failRender = true;
    run((async, u) {
      u.start();
      async.flushMicrotasks();
      expect(host.publishes, 0);
      async.elapse(minute);
      expect(host.publishes, 1);
    });
  });

  test('a DayLog failure in onFix does not throw to the caller', () {
    days.failAppend = true;
    run((async, u) {
      expect(() => u.onFix(fix(base)), returnsNormally);
      async.flushMicrotasks();
    });
  });
}
