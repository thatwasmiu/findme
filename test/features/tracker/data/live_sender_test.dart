import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:findme/features/tracker/data/live_sender.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/tracker_fakes.dart';

Fix north(double m, {double acc = 5}) => Fix(
  at: DateTime.utc(2026, 11, 24, 8),
  lat: 10.77 + m / 111195,
  lon: 106.7,
  acc: acc,
);

void main() {
  late FakeLink link;
  late IngestToken? token;
  late LiveSender live;
  late bool passOk;
  late List<String> asked;

  /// The broker's 15-minute pass from `/mqtt-pass`: a new one each time, null while [passOk] is false.
  Future<String?> pass(String ingestToken) async {
    if (!passOk) return null;
    asked.add(ingestToken);
    return 'pass-${asked.length}';
  }

  void make(FakeAsync a) {
    final start = DateTime.utc(2026, 11, 24, 8);
    live = LiveSender(
      link,
      () async => token,
      pass,
      now: () => start.add(a.elapsed),
    );
  }

  List<double> lats() => [
    for (final s in link.sent)
      if (s.payload.isNotEmpty)
        (jsonDecode(s.payload) as Map<String, dynamic>)['lat'] as double,
  ];

  setUp(() {
    link = FakeLink();
    token = (token: 'tok', sub: 'acct-1');
    passOk = true;
    asked = [];
  });

  test('connects with the pass, not the ingest token', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      expect(link.connects, hasLength(1));
      expect(link.connects.single.clientId, startsWith('acct-1/phone-'));
      expect(asked, ['tok']);
      expect(link.connects.single.password, 'pass-1');
    });
  });

  test('no pass: retries later', () {
    fakeAsync((a) {
      passOk = false;
      make(a);
      live.start();
      a.flushMicrotasks();
      expect(link.connects, isEmpty);
      passOk = true;
      a.elapse(const Duration(seconds: 2));
      expect(link.connects.single.password, 'pass-1');
    });
  });

  test('kicked at exp reconnects with a new pass', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      a.elapse(const Duration(minutes: 15));
      link.drop(); // the broker closes the connection when the pass expires
      a.elapse(const Duration(seconds: 2));
      expect(link.connects.map((c) => c.password), ['pass-1', 'pass-2']);
    });
  });

  test('clear after a long gap gets a fresh pass', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      link
        ..drop()
        ..accept = false; // unreachable for half an hour: pass-1 long expired
      a.elapse(const Duration(minutes: 30));
      link.accept = true;
      final before = link.connects.length;
      final passes = asked.length;
      unawaited(live.stop());
      a.elapse(const Duration(seconds: 2));
      expect(link.connects.length, before + 1);
      expect(
        link.connects.last.password,
        'pass-${passes + 1}',
      ); // asked again for the clear
      expect(link.sent.last.payload, '');
    });
  });

  test('publishes moved fixes to live/<id>, skips jitter', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      live.onFix(north(0));
      a.elapse(const Duration(seconds: 2));
      live.onFix(north(3)); // under 5 m
      a.elapse(const Duration(seconds: 2));
      live.onFix(north(10));
      a.flushMicrotasks();
      expect(link.sent.map((s) => s.topic).toSet(), {'live/acct-1'});
      expect(lats(), hasLength(2));
    });
  });

  test(
    'at most one a second: a fix inside the second waits, the newest wins',
    () {
      fakeAsync((a) {
        make(a);
        live.start();
        a.flushMicrotasks();
        live.onFix(north(0));
        a.elapse(const Duration(milliseconds: 300));
        live
          ..onFix(north(10))
          ..onFix(north(20));
        expect(link.sent, hasLength(1));
        a.elapse(const Duration(milliseconds: 700));
        expect(link.sent, hasLength(2));
        expect(lats().last, closeTo(10.77 + 20 / 111195, 1e-6));
      });
    },
  );

  test(
    'offline fixes: the newest goes on connect; the wait doubles to 60 s',
    () {
      fakeAsync((a) {
        link.accept = false;
        make(a);
        live.start();
        a.flushMicrotasks();
        live
          ..onFix(north(0))
          ..onFix(north(10));
        expect(link.sent, isEmpty);
        final waits = <int>[];
        for (var i = 0; i < 8; i++) {
          final before = link.connects.length;
          var waited = 0;
          while (link.connects.length == before) {
            a.elapse(const Duration(seconds: 1));
            waited++;
          }
          waits.add(waited);
        }
        expect(waits, [2, 4, 8, 16, 32, 60, 60, 60]);
        link.accept = true;
        a.elapse(const Duration(seconds: 60));
        expect(lats(), [closeTo(10.77 + 10 / 111195, 1e-6)]);
      });
    },
  );

  test('kicked at once (no trip open yet): the wait keeps growing', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      live.onFix(north(0));
      link.drop();
      a.elapse(const Duration(seconds: 2));
      expect(link.connects, hasLength(2));
      expect(link.sent, hasLength(2), reason: 'the newest fix is sent again');
      link.drop();
      a.elapse(const Duration(seconds: 3));
      expect(link.connects, hasLength(2));
      a.elapse(const Duration(seconds: 1));
      expect(link.connects, hasLength(3));
    });
  });

  test('a connection that lasted a minute resets the wait to 2 s', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      link.drop();
      a.elapse(
        const Duration(seconds: 2),
      ); // 2nd connect; the next wait would be 4 s
      a.elapse(const Duration(seconds: 61));
      link.drop();
      a.elapse(const Duration(seconds: 2));
      expect(link.connects, hasLength(3));
    });
  });

  test('no token yet: tries again later, without connecting', () {
    fakeAsync((a) {
      token = null;
      make(a);
      live.start();
      a.flushMicrotasks();
      expect(link.connects, isEmpty);
      token = (token: 'tok', sub: 'acct-1');
      a.elapse(const Duration(seconds: 2));
      expect(link.connects, hasLength(1));
    });
  });

  test('stop clears the retained position, then disconnects', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      live.onFix(north(0));
      var done = false;
      unawaited(live.stop().then((_) => done = true));
      a.flushMicrotasks();
      expect(link.sent.last, (topic: 'live/acct-1', payload: ''));
      expect(link.disconnects, 0, reason: 'the clear gets a moment to leave');
      a.elapse(const Duration(seconds: 1));
      expect(done, isTrue);
      expect(link.disconnects, 1);
      // nothing after the stop
      live.onFix(north(50));
      link.drop();
      a.elapse(const Duration(minutes: 5));
      expect(link.connects, hasLength(1));
      expect(link.sent, hasLength(2));
    });
  });

  test('stop while disconnected: one connect just to clear', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      link.drop();
      unawaited(live.stop());
      a.elapse(const Duration(seconds: 2));
      expect(link.connects, hasLength(2));
      expect(link.sent.single.payload, '');
      expect(link.disconnects, 1);
      a.elapse(const Duration(minutes: 5));
      expect(link.connects, hasLength(2));
    });
  });

  test('stop before any connection: nothing to clear', () {
    fakeAsync((a) {
      token = null;
      make(a);
      live.start();
      a.flushMicrotasks();
      unawaited(live.stop());
      a.elapse(const Duration(minutes: 1));
      expect(link.connects, isEmpty);
    });
  });

  test('stop during a slow connect: nothing published, connection closed', () {
    fakeAsync((a) {
      link.hold = Completer();
      make(a);
      live.start();
      a.flushMicrotasks();
      unawaited(live.stop());
      a.flushMicrotasks();
      link.hold!.complete(true);
      a.elapse(const Duration(seconds: 5));
      expect(link.sent, isEmpty);
      expect(link.up, isFalse);
    });
  });

  test('start right after a stop: the clear finishes first, the new run stays live', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      link.drop(); // the clear needs its own connect
      link.hold = Completer();
      unawaited(live.stop());
      a.flushMicrotasks();
      live.start(); // a new trip while the clear is still connecting
      live.onFix(north(0));
      link.hold!.complete(true);
      link.hold = null;
      a.elapse(const Duration(seconds: 5));
      expect(link.sent.first.payload, '');
      expect(
        link.up,
        isTrue,
        reason: "the clear's disconnect must not close the new run",
      );
      expect(lats(), hasLength(1));
    });
  });

  test('start again after a stop works', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      unawaited(live.stop());
      a.elapse(const Duration(seconds: 2));
      live.start();
      a.flushMicrotasks();
      live.onFix(north(0));
      expect(link.connects, hasLength(2));
      expect(lats(), hasLength(1));
    });
  });

  test('a publish that throws never escapes', () {
    fakeAsync((a) {
      make(a);
      live.start();
      a.flushMicrotasks();
      link.up = false; // dropped, not yet told
      expect(() => live.onFix(north(0)), returnsNormally);
    });
  });

  test('debug log: what happened, never token, id, topic or position', () {
    fakeAsync((a) {
      final events = <String>[];
      final start = DateTime.utc(2026, 11, 24, 8);
      link.accept = false;
      live = LiveSender(
        link,
        () async => token,
        pass,
        now: () => start.add(a.elapsed),
        log: events.add,
      )..start();
      a.flushMicrotasks();
      link.accept = true;
      a.elapse(const Duration(seconds: 2));
      live.onFix(north(0));
      a.elapse(const Duration(seconds: 5));
      link.drop();
      a.elapse(const Duration(seconds: 4));
      unawaited(live.stop());
      a.elapse(const Duration(seconds: 2));
      expect(events, [
        'connecting',
        'refused or unreachable',
        'retry in 2 s',
        'connecting',
        'connected',
        'published (acc 5 m)',
        'dropped after 5 s',
        'retry in 4 s',
        'connecting',
        'connected',
        'published (acc 5 m)',
        'cleared, disconnected',
      ]);
      final all = events.join(' ');
      for (final secret in [
        'tok',
        'pass-',
        'acct-1',
        'live/',
        '10.77',
        '106.7',
      ]) {
        expect(all, isNot(contains(secret)));
      }
    });
  });

  test('debug log: no token yet', () {
    fakeAsync((a) {
      final events = <String>[];
      token = null;
      live = LiveSender(link, () async => token, pass, log: events.add)
        ..start();
      a.flushMicrotasks();
      expect(events, ['no ingest token yet', 'retry in 2 s']);
    });
  });
}
