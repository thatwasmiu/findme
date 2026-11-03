import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

final now = DateTime(2026, 10, 28, 15);

Track trackWithLast(String ts, [List<TrackPoint> points = const []]) => Track(
  points: points,
  last: LastPoint(lon: 1, lat: 2, ts: ts),
);

void main() {
  setUpAll(() => registerFallbackValue(const DateRange(from: '', to: '')));

  late MockTrack repo;
  late List<DateRange> asked;
  late ProviderContainer c;

  /// Signed in, clock frozen at [now]; `answer` decides what /track returns.
  void start(FakeAsync f, Future<Track> Function(DateRange r) answer) {
    repo = MockTrack();
    asked = [];
    when(() => repo.fetch(any())).thenAnswer((i) {
      final r = i.positionalArguments.single as DateRange;
      asked.add(r);
      return answer(r);
    });
    c = ProviderContainer(
      overrides: [
        ...baseOverrides(auth: fakeAuth(), track: repo),
        nowProvider.overrideWithValue(() => now),
      ],
    );
    c
      ..listen(trailControllerProvider, (_, _) {})
      ..read(authControllerProvider);
    f.elapse(Duration.zero);
  }

  TrailState state() => c.read(trailControllerProvider);
  TrailController ctl() => c.read(trailControllerProvider.notifier);

  test('first load: today, the whole range', () {
    fakeAsync((f) {
      start(f, (_) async => trackWithLast('A'));
      expect(asked, hasLength(1));
      expect(asked.single.from, presetRange(Preset.today, now).from);
      expect(asked.single.to, isoMs(now));
      expect(state().track.last?.ts, 'A');
      expect(state().loading, isFalse);
    });
  });

  test(
    'refresh fetches only the tail and merges it; backs off 7→14→28→56→60 s',
    () {
      fakeAsync((f) {
        final p1 = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);
        start(f, (_) async => trackWithLast('A', [p1]));
        f.elapse(const Duration(seconds: 7));
        expect(asked, hasLength(2));
        expect(
          asked[1].from,
          isoMs(DateTime.fromMillisecondsSinceEpoch((p1.t - 900) * 1000)),
        );
        for (final gap in [14, 28, 56, 60, 60]) {
          f.elapse(Duration(seconds: gap - 1));
          final before = asked.length;
          f.elapse(const Duration(seconds: 1));
          expect(asked.length, before + 1, reason: 'next refresh after $gap s');
        }
      });
    },
  );

  test('new prints: back to 7 s', () {
    fakeAsync((f) {
      var n = 0;
      start(f, (_) async => trackWithLast('T${n++ < 4 ? 0 : n}'));
      f.elapse(
        const Duration(seconds: 7 + 14 + 28),
      ); // three quiet refreshes, delay now 56 s
      final before = asked.length;
      f.elapse(const Duration(seconds: 56)); // this one brings a new last point
      f.elapse(const Duration(seconds: 7));
      expect(asked.length, before + 2);
    });
  });

  test(
    'past range: no fetch, but the state ticks so "x phút trước" moves on',
    () {
      fakeAsync((f) {
        start(f, (_) async => Track.empty);
        ctl().setRange(presetRange(Preset.yesterday, now));
        f.elapse(Duration.zero);
        final fetched = asked.length;
        final tick = state().tick;
        f.elapse(const Duration(seconds: 7));
        expect(asked.length, fetched);
        expect(state().tick, greaterThan(tick));
      });
    },
  );

  test(
    '400 on a full load says "max 31 days"; other errors the generic line',
    () {
      fakeAsync((f) {
        start(f, (_) async => throw const HttpError(400));
        expect(state().error, 'Chọn tối đa 31 ngày một lần nhé 📅');
      });
      fakeAsync((f) {
        start(f, (_) async => throw const NetworkError());
        expect(
          state().error,
          'Chưa tải được dấu chân — thử lại sau chút nhé ✨',
        );
      });
    },
  );

  test('quiet refresh failure keeps trail and shows no error', () {
    fakeAsync((f) {
      var fail = false;
      start(
        f,
        (_) async => fail ? throw const NetworkError() : trackWithLast('A'),
      );
      fail = true;
      f.elapse(const Duration(seconds: 7));
      expect(state().track.last?.ts, 'A');
      expect(state().error, isNull);
    });
  });

  test('401 -> signed out (and the trail is gone); 403 -> no account', () {
    fakeAsync((f) {
      start(f, (_) async => throw const AuthExpired());
      expect(c.read(authControllerProvider), AuthPhase.signedOut);
      expect(state().track, Track.empty);
    });
    fakeAsync((f) {
      start(f, (_) async => throw const AccountMissing());
      expect(c.read(authControllerProvider), AuthPhase.noAccount);
    });
  });

  test('stale load is ignored', () {
    fakeAsync((f) {
      final first = Completer<Track>();
      var call = 0;
      start(
        f,
        (_) => call++ == 0 ? first.future : Future.value(trackWithLast('NEW')),
      );
      ctl().setRange(presetRange(Preset.d7, now));
      f.elapse(Duration.zero);
      first.complete(trackWithLast('OLD'));
      f.elapse(Duration.zero);
      expect(state().track.last?.ts, 'NEW');
      expect(state().range, presetRange(Preset.d7, now));
    });
  });

  test(
    'resume refreshes at once and resets the backoff; paused does nothing',
    () {
      fakeAsync((f) {
        start(f, (_) async => trackWithLast('A'));
        f.elapse(const Duration(seconds: 7 + 14)); // delay now 28 s
        ctl().paused();
        final before = asked.length;
        f.elapse(const Duration(minutes: 5));
        expect(asked.length, before);
        ctl().resumed();
        f.elapse(Duration.zero);
        expect(asked.length, before + 1);
        // Like the web: the resume refresh found nothing new, so the next one doubles from 7 s to 14 s.
        f.elapse(const Duration(seconds: 13));
        expect(asked.length, before + 1);
        f.elapse(const Duration(seconds: 1));
        expect(asked.length, before + 2);
      });
    },
  );
}
