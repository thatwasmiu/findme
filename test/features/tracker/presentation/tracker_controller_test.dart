import 'dart:async';
import 'dart:io';

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

  test('no token -> queues, problem noToken, send never called', () async {
    store.saved = null;
    await ctl().turnOn();
    await emit(3);
    expect(st().problem, TrackerProblem.noToken);
    expect(st().queued, 3);
    verifyNever(() => ingest.send(any(), any(), any()));
  });

  test('401 -> badToken; saveToken clears it, the next fix uploads', () async {
    answer(IngestResult.unauthorized);
    await ctl().turnOn();
    await emit(1);
    expect(st().problem, TrackerProblem.badToken);
    await emit(60);
    verify(() => ingest.send(any(), any(), any())).called(1);
    expect(st().queued, 61);
    answer(IngestResult.ok);
    await ctl().saveToken('  new  ');
    expect(store.saved, (token: 'new', sub: 'sub-1'));
    expect(st().problem, TrackerProblem.none);
    await ctl().idle();
    // A new token sends what waited at once.
    verify(() => ingest.send('new', any(that: hasLength(61)), any())).called(1);
    expect(st().queued, 0);
  });

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
}
