import 'dart:async';
import 'dart:io';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/tracker/data/ingest_client.dart';
import 'package:findme/features/tracker/data/point_queue.dart';
import 'package:findme/features/tracker/data/wake_channel.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/tracker_fakes.dart';

var _s = 0;
Fix fx() => Fix(
  at: DateTime.utc(2026, 11, 4).add(Duration(seconds: _s++)),
  lat: 10.77,
  lon: 106.7,
  acc: 9,
);

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() => registerFallbackValue(<Fix>[]));

  late Directory dir;
  late PointQueue queue;
  late MemoryTrackerStore store;
  late FakeLocation gps;
  late FakeWake wake;
  late MockIngest ingest;
  late DateTime now;
  late ProviderContainer c;

  TrackerController ctl() => c.read(trackerControllerProvider.notifier);
  TrackerState st() => c.read(trackerControllerProvider);
  void answer(IngestResult r) =>
      when(() => ingest.send(any(), any(), any())).thenAnswer((_) async => r);
  Future<void> emit(int n, {bool waitUploads = true}) async {
    for (var i = 0; i < n; i++) {
      gps.emit(fx());
      await settle();
      await ctl().idle(uploads: waitUploads);
    }
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tracker');
    queue = PointQueue(dir);
    store = MemoryTrackerStore()..saved = (token: 'tok', sub: 'sub-1');
    gps = FakeLocation();
    wake = FakeWake();
    ingest = MockIngest();
    now = DateTime.utc(2026, 11, 4, 12);
    answer(IngestResult.ok);
    when(() => ingest.newToken()).thenAnswer((_) async => 'issued');
    c = ProviderContainer(
      overrides: [
        ...baseOverrides(
          auth: fakeAuth(token: jwt('sub-1')),
          trackerStore: store,
          fakeTracker: false,
        ),
        pointQueueProvider.overrideWith((_) async => queue),
        locationSourceProvider.overrideWithValue(gps),
        wakeChannelProvider.overrideWithValue(wake),
        ingestClientProvider.overrideWithValue(ingest),
        trackerClockProvider.overrideWithValue(() => now),
      ],
    );
  });
  tearDown(() {
    c.dispose();
    dir.deleteSync(recursive: true);
  });

  test('turnOn without always -> needAlways, not listening', () async {
    gps.afterRequest = LocationAccess.whileInUse;
    await ctl().turnOn();
    expect(st().problem, TrackerProblem.needAlways);
    expect(st().on, isFalse);
    expect(gps.listening, isFalse);
    expect(store.on, isFalse);
  });

  test(
    'fixes are queued and the 50th triggers an upload; ok commits',
    () async {
      await ctl().turnOn();
      expect(store.on, isTrue);
      expect(st().on, isTrue);
      // The very first fix uploads (nothing sent yet); after that, wait for 50.
      await emit(1);
      verify(() => ingest.send('tok', any(), any())).called(1);
      await emit(49);
      verifyNever(() => ingest.send(any(), any(), any()));
      expect(st().queued, 49);
      await emit(1);
      verify(() => ingest.send('tok', any(that: hasLength(50)), any()))
          .called(1);
      expect(st().queued, 0);
      expect(st().lastOk, now);
      expect(st().lastFix, isNotNull);
    },
  );

  void issues(Future<String> Function() f) =>
      when(() => ingest.newToken()).thenAnswer((_) => f());
  void signedInAs(String? token) =>
      when(() => c.read(authRepositoryProvider).getAccessToken())
          .thenAnswer((_) async => token);

  test('no token -> turnOn asks the server for one and keeps it', () async {
    store.saved = null;
    issues(() async => 'fresh');
    await ctl().turnOn();
    await ctl().idle();
    expect(store.saved, (token: 'fresh', sub: 'sub-1'));
    expect(st().problem, TrackerProblem.none);
    await emit(1);
    verify(() => ingest.send('fresh', any(), any())).called(1);
  });

  test(
    'no token while offline -> noToken, queued, asked again after the backoff',
    () async {
      store.saved = null;
      issues(() async => throw const NetworkError());
      await ctl().turnOn();
      await emit(3);
      expect(st().problem, TrackerProblem.noToken);
      expect(st().queued, 3);
      verify(() => ingest.newToken())
          .called(1); // the backoff holds the next fixes back
      verifyNever(() => ingest.send(any(), any(), any()));
      issues(() async => 'fresh');
      now = now.add(const Duration(minutes: 2));
      await emit(1);
      expect(st().problem, TrackerProblem.none);
      verify(() => ingest.send('fresh', any(that: hasLength(4)), any()))
          .called(1);
    },
  );

  test('no token, signed out -> noToken, nothing asked', () async {
    store
      ..saved = null
      ..owned = 'sub-1'
      ..on = true;
    signedInAs(null);
    await ctl().resume();
    await emit(2);
    expect(st().problem, TrackerProblem.noToken);
    verifyNever(() => ingest.newToken());
  });

  test('someone else signed in -> no token is asked for them', () async {
    store
      ..saved = null
      ..owned = 'sub-1'
      ..on = true;
    signedInAs(jwt('sub-2'));
    await ctl().resume();
    await emit(1);
    expect(st().problem, TrackerProblem.noToken);
    verifyNever(() => ingest.newToken());
  });

  test('403 -> noAccount, not asked again until Gửi ngay', () async {
    store.saved = null;
    issues(() async => throw const AccountMissing());
    await ctl().turnOn();
    await emit(3);
    expect(st().problem, TrackerProblem.noAccount);
    verify(() => ingest.newToken()).called(1);
    await ctl().sendNow();
    verify(() => ingest.newToken()).called(1);
  });

  test('sign-in 401 -> noToken and the usual signed-out screen', () async {
    store.saved = null;
    issues(() async => throw const AuthExpired());
    c.read(authControllerProvider.notifier).state = AuthPhase.signedIn;
    await ctl().turnOn();
    await ctl().idle();
    expect(st().problem, TrackerProblem.noToken);
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
  });

  test('ingest 401 -> a new token once, and the batch goes out', () async {
    var n = 0;
    when(() => ingest.send(any(), any(), any())).thenAnswer(
      (_) async => n++ == 0 ? IngestResult.unauthorized : IngestResult.ok,
    );
    issues(() async => 'new');
    await ctl().turnOn();
    await emit(1);
    verify(() => ingest.send('tok', any(), any())).called(1);
    verify(() => ingest.send('new', any(that: hasLength(1)), any())).called(1);
    expect(store.saved, (token: 'new', sub: 'sub-1'));
    expect(st().problem, TrackerProblem.none);
    expect(st().queued, 0);
  });

  test(
    'a fresh token refused too -> badToken, asked again after the backoff',
    () async {
      answer(IngestResult.unauthorized);
      issues(() async => 'new');
      await ctl().turnOn();
      await emit(1);
      expect(st().problem, TrackerProblem.badToken);
      verify(() => ingest.newToken()).called(1);
      await emit(5);
      verifyNever(() => ingest.newToken());
      answer(IngestResult.ok);
      now = now.add(const Duration(minutes: 2));
      await emit(1);
      verify(() => ingest.newToken()).called(1);
      expect(st().problem, TrackerProblem.none);
      expect(st().queued, 0);
    },
  );

  test('400 -> that batch is rejected, the rest is still sent', () async {
    for (var i = 0; i < 600; i++) {
      await queue.append(fx());
    }
    var calls = 0;
    when(() => ingest.send(any(), any(), any())).thenAnswer(
      (_) async => calls++ == 0 ? IngestResult.rejected : IngestResult.ok,
    );
    await ctl().resume();
    await ctl().sendNow();
    expect(calls, 2);
    expect(st().rejected, 500);
    expect(st().queued, 0);
  });

  test('retry -> backoff: no send for 1 min, then send', () async {
    answer(IngestResult.retry);
    await ctl().turnOn();
    await emit(1);
    verify(() => ingest.send(any(), any(), any())).called(1);
    now = now.add(const Duration(seconds: 30));
    await emit(60);
    verifyNever(() => ingest.send(any(), any(), any()));
    now = now.add(const Duration(seconds: 31));
    answer(IngestResult.ok);
    await emit(1);
    verify(() => ingest.send(any(), any(), any())).called(1);
    expect(st().queued, 0);
  });

  test('no overlapping uploads, every fix sent exactly once', () async {
    final hold = Completer<IngestResult>();
    final sent = <Fix>[];
    when(() => ingest.send(any(), any(), any())).thenAnswer((i) {
      sent.addAll(i.positionalArguments[1] as List<Fix>);
      return sent.length <= 2 ? hold.future : Future.value(IngestResult.ok);
    });
    await ctl().turnOn();
    await emit(61, waitUploads: false);
    // One upload is in flight; the other fixes only queue.
    verify(() => ingest.send(any(), any(), any())).called(1);
    expect(st().queued, 61);
    hold.complete(IngestResult.ok);
    await ctl().idle();
    expect(sent.toSet().length, 61);
    expect(sent.length, 61);
    expect(st().queued, 0);
  });

  test('sendNow ignores the backoff window', () async {
    answer(IngestResult.retry);
    await ctl().turnOn();
    await emit(1);
    answer(IngestResult.ok);
    await ctl().sendNow();
    expect(st().queued, 0);
  });

  test('resume: flag on + always -> listening; after turnOff -> not', () async {
    store.on = true;
    await ctl().resume();
    expect(gps.listening, isTrue);
    expect(st().on, isTrue);
    await ctl().turnOff();
    expect(gps.listening, isFalse);
    expect(store.on, isFalse);
    await ctl().resume();
    expect(gps.listening, isFalse);
  });

  test('resume with flag on but access lost -> needAlways', () async {
    store.on = true;
    gps.granted = LocationAccess.whileInUse;
    await ctl().resume();
    expect(gps.listening, isFalse);
    expect(st().problem, TrackerProblem.needAlways);
  });

  test('forget tries one last upload, then clears queue and token', () async {
    answer(IngestResult.retry);
    await ctl().turnOn();
    await emit(3);
    await ctl().forget();
    expect(gps.listening, isFalse);
    expect(await queue.count(), 0);
    expect(store.saved, isNull);
    expect(store.forgets, 1);
    expect(st().on, isFalse);
  });

  test('significant-change monitoring follows the switch', () async {
    await ctl().turnOn();
    expect(wake.starts, 1);
    await ctl().turnOff();
    expect(wake.stops, 1);
    store.on = true;
    await ctl().resume();
    expect(wake.starts, 2); // iOS wants it restarted after a relaunch
    await ctl().forget();
    expect(wake.stops, 2);
  });

  test('a wake re-subscribes to GPS while on (iOS paused it)', () async {
    await ctl().turnOn();
    expect(gps.listens, 1);
    wake.fire();
    await settle();
    expect(gps.listens, 2);
    expect(gps.listening, isTrue);
    await ctl().turnOff();
    wake.fire();
    await settle();
    expect(gps.listens, 2);
  });

  test('forget waits for a running upload, then sends the rest', () async {
    final hold = Completer<IngestResult>();
    var calls = 0;
    when(() => ingest.send(any(), any(), any())).thenAnswer((_) {
      calls++;
      return calls == 1 ? hold.future : Future.value(IngestResult.ok);
    });
    await ctl().turnOn();
    await emit(
      4,
      waitUploads: false,
    ); // 1st fix in flight, 3 more queue behind it
    final gone = ctl().forget();
    hold.complete(IngestResult.ok);
    await gone;
    expect(calls, 2);
    expect(store.saved, isNull);
  });

  test('a fix still being written does not survive forget', () async {
    store.saved = null;
    await ctl().turnOn();
    gps.emit(fx()); // not awaited: forget races the append
    await ctl().forget();
    await settle();
    expect(await queue.count(), 0);
  });

  test('turnOn remembers whose tracking this is', () async {
    store.saved = null;
    await ctl().turnOn();
    expect(await store.owner(), 'sub-1');
  });

  test(
    'the location indicator restarts GPS with it and is remembered',
    () async {
      await ctl().turnOn();
      expect(gps.lastIndicator, isFalse);
      await ctl().setIndicator(on: true);
      expect(gps.listens, 2);
      expect(gps.lastIndicator, isTrue);
      expect(gps.listening, isTrue);
      expect(store.indicatorOn, isTrue);
      expect(st().indicator, isTrue);
    },
  );

  test('indicator while off: saved, GPS not started', () async {
    await ctl().setIndicator(on: true);
    expect(gps.listens, 0);
    expect(store.indicatorOn, isTrue);
  });

  test('resume uses the saved indicator setting', () async {
    store
      ..on = true
      ..indicatorOn = true;
    await ctl().resume();
    expect(gps.lastIndicator, isTrue);
    expect(st().indicator, isTrue);
  });

  test('a shorter interval sends what waits once it is due', () async {
    await ctl().turnOn();
    await emit(1); // first upload: lastOk = now
    await emit(3);
    verify(() => ingest.send(any(), any(), any())).called(1);
    now = now.add(const Duration(seconds: 10));
    await ctl().setUploadEvery(const Duration(seconds: 5));
    await ctl().idle();
    verify(() => ingest.send(any(), any(that: hasLength(3)), any())).called(1);
    expect(store.every, const Duration(seconds: 5));
    expect(st().uploadEvery, const Duration(seconds: 5));
  });

  test('a longer interval holds fixes past the default', () async {
    store.every = const Duration(minutes: 2);
    await ctl().turnOn();
    await emit(1);
    verify(() => ingest.send(any(), any(), any())).called(1);
    now = now.add(const Duration(seconds: 90));
    await emit(3);
    verifyNever(() => ingest.send(any(), any(), any()));
    expect(st().uploadEvery, const Duration(minutes: 2));
  });

  test(
    'token unreadable (locked iPhone): fixes wait, no new token asked',
    () async {
      await ctl().turnOn();
      await emit(1);
      clearInteractions(ingest);
      store.locked = true;
      now = now.add(const Duration(minutes: 5));
      await emit(3);
      verifyNever(() => ingest.newToken());
      verifyNever(() => ingest.send(any(), any(), any()));
      expect(st().problem, isNot(TrackerProblem.noToken));
      expect(st().queued, 3);
      store.locked = false;
      await emit(1);
      verify(() => ingest.send('tok', any(that: hasLength(4)), any()))
          .called(1);
    },
  );

  test('resume while locked does not say "no token"', () async {
    store
      ..on = true
      ..locked = true;
    await ctl().resume();
    expect(st().on, isTrue);
    expect(st().problem, TrackerProblem.none);
  });
}
