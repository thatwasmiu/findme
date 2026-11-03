import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
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

/// An access token whose payload carries [sub] (the signature is never checked here).
String jwt(String sub) =>
    'h.${base64Url.encode(utf8.encode(jsonEncode({'sub': sub}))).replaceAll('=', '')}.s';

void main() {
  setUpAll(() => registerFallbackValue(const DateRange(from: '', to: '')));

  late MockTrack repo;
  late List<DateRange> asked;
  late List<({String? have, String? friends})> opts;
  late ProviderContainer c;

  /// Signed in, clock frozen at [now]; `answer` decides what /track returns (a Track, or a whole TrackAnswer).
  void start(
    FakeAsync f,
    FutureOr<Object> Function(DateRange r) answer, {
    String token = 't',
    MemoryPrefs? prefs,
    MockFriends? friends,
  }) {
    repo = MockTrack();
    asked = [];
    opts = [];
    when(
      () => repo.fetch(
        any(),
        have: any(named: 'have'),
        friends: any(named: 'friends'),
      ),
    ).thenAnswer((i) async {
      final r = i.positionalArguments.single as DateRange;
      asked.add(r);
      opts.add((
        have: i.namedArguments[#have] as String?,
        friends: i.namedArguments[#friends] as String?,
      ));
      final a = await answer(r);
      return a is TrackAnswer ? a : TrackAnswer(a as Track);
    });
    c = ProviderContainer(
      overrides: [
        ...baseOverrides(
          auth: fakeAuth(token: token),
          track: repo,
          prefs: prefs,
          friends: friends,
        ),
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

  test('every 60 s: only the tail, with `have`', () {
    fakeAsync((f) {
      final p1 = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);
      start(f, (_) async => trackWithLast('A', [p1]));
      expect(opts.single.have, isNull);
      f.elapse(const Duration(seconds: 59));
      expect(asked, hasLength(1));
      f.elapse(const Duration(seconds: 1));
      expect(asked, hasLength(2));
      expect(
        asked[1].from,
        isoMs(DateTime.fromMillisecondsSinceEpoch((p1.t - 900) * 1000)),
      );
      expect(opts[1].have, 'A');
      f.elapse(const Duration(seconds: 60));
      expect(asked, hasLength(3));
    });
  });

  test('`unchanged`: the trail stays, only the newest point moves on', () {
    fakeAsync((f) {
      final p1 = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);
      var n = 0;
      start(
        f,
        (_) => n++ == 0
            ? trackWithLast('A', [p1])
            : TrackAnswer(trackWithLast('B'), unchanged: true),
      );
      f.elapse(const Duration(seconds: 60));
      expect(state().track.points, [p1]);
      expect(state().track.last?.ts, 'B');
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
        f.elapse(const Duration(seconds: 60));
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
      f.elapse(const Duration(seconds: 60));
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

  test('resume refreshes at once; paused does nothing', () {
    fakeAsync((f) {
      start(f, (_) async => trackWithLast('A'));
      ctl().paused();
      f.elapse(const Duration(minutes: 5));
      expect(asked, hasLength(1));
      ctl().resumed();
      f.elapse(Duration.zero);
      expect(asked, hasLength(2));
    });
  });

  test('unnamed stops after a full load: one full reload 20 s later picks up names', () {
    fakeAsync((f) {
      final today = presetRange(Preset.today, now);
      final p = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);
      final stop = Stop(
        lon: 1,
        lat: 1,
        start: isoMs(DateTime(2026, 10, 28, 10)),
        end: isoMs(DateTime(2026, 10, 28, 11)),
        seconds: 3600,
      );
      start(
        f,
        (_) async => Track(
          points: [p],
          stops: [stop],
          last: const LastPoint(lon: 1, lat: 1, ts: 'A'),
        ),
      );
      f.elapse(const Duration(seconds: 100));
      expect(asked.where((r) => r.from == today.from), hasLength(2));
    });
  });

  test('named stops: no extra full reload', () {
    fakeAsync((f) {
      final today = presetRange(Preset.today, now);
      final p = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);
      start(
        f,
        (_) async => Track(
          points: [p],
          last: const LastPoint(lon: 1, lat: 1, ts: 'A'),
        ),
      );
      f.elapse(const Duration(seconds: 100));
      expect(asked.where((r) => r.from == today.from), hasLength(1));
    });
  });

  test('switching range during a background refresh keeps the 60 s rhythm', () {
    fakeAsync((f) {
      final gate = Completer<Track>();
      var call = 0;
      start(f, (_) {
        call++;
        return call == 2 ? gate.future : Future.value(trackWithLast('A'));
      });
      f.elapse(const Duration(seconds: 60)); // the quiet refresh hangs
      ctl().setRange(presetRange(Preset.d7, now));
      f.elapse(Duration.zero);
      gate.complete(trackWithLast('A'));
      f.elapse(Duration.zero);
      final before = asked.length;
      f.elapse(const Duration(seconds: 60));
      expect(asked.length, before + 1);
    });
  });

  group('today kept on the phone', () {
    final day = presetRange(Preset.today, now).from;
    final p1 = TrackPoint(1, 1, now.millisecondsSinceEpoch ~/ 1000 - 60);

    test('written after a load of "Hôm nay"; reopening draws it at once and '
        'asks only for the tail', () {
      final prefs = MemoryPrefs();
      fakeAsync((f) {
        start(
          f,
          (_) async => trackWithLast('A', [p1]),
          token: jwt('me'),
          prefs: prefs,
        );
        expect(prefs.today?.who, 'me');
        expect(prefs.today?.day, day);
        expect(prefs.today?.cache.mine.points, [p1]);
      });
      fakeAsync((f) {
        start(
          f,
          (_) async => TrackAnswer(trackWithLast('A'), unchanged: true),
          token: jwt('me'),
          prefs: prefs,
        );
        expect(asked.single.from, isNot(day));
        expect(opts.single.have, 'A');
        expect(state().track.points, [p1]);
      });
    });

    test('another account: not used, and replaced', () {
      final prefs = MemoryPrefs()
        ..today = (
          who: 'someone',
          day: day,
          cache: (mine: trackWithLast('X', [p1]), friends: const {}),
        );
      fakeAsync((f) {
        start(f, (_) async => Track.empty, token: jwt('me'), prefs: prefs);
        expect(asked.single.from, day);
        expect(state().track, Track.empty);
        expect(prefs.today?.who, 'me');
      });
    });

    test('a past range is not kept', () {
      final prefs = MemoryPrefs();
      fakeAsync((f) {
        start(f, (_) async => Track.empty, token: jwt('me'), prefs: prefs);
        prefs.today = null;
        ctl().setRange(presetRange(Preset.yesterday, now));
        f.elapse(Duration.zero);
        expect(prefs.today, isNull);
      });
    });

    test('signing out forgets it', () {
      final prefs = MemoryPrefs();
      fakeAsync((f) {
        start(f, (_) async => Track.empty, token: jwt('me'), prefs: prefs);
        expect(prefs.today, isNotNull);
        c.read(authControllerProvider.notifier).expired();
        f.elapse(Duration.zero);
        expect(prefs.today, isNull);
      });
    });
  });

  test(
    'shown friends ride along; a friend coming on the map is asked for at once',
    () {
      fakeAsync((f) {
        final friends = MockFriends();
        when(friends.me)
            .thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K'));
        when(friends.relations).thenAnswer(
          (_) async => const Relations(
            friends: [Friend(id: 'b', name: 'Bình', since: 'S')],
          ),
        );
        start(
          f,
          (_) async => trackWithLast('A'),
          prefs: MemoryPrefs()..shown = ['b'],
          friends: friends,
        );
        // The first request went out before the friend list was in; the list brought 'b' on the map.
        expect(opts.map((o) => o.friends), ['', 'b~~']);
      });
    },
  );
}
