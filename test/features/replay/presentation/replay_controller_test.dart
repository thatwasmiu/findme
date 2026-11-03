import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/replay/presentation/replay_controller.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

const own = [
  TrackPoint(1, 1, 1000),
  TrackPoint(2, 2, 2000),
  TrackPoint(3, 3, 3000),
];

void main() {
  setUpAll(() => registerFallbackValue(const DateRange(from: '', to: '')));

  late ProviderContainer c;
  setUp(() async {
    final track = MockTrack();
    stubFetch(track, (_) async => Track.empty);
    c =
        ProviderContainer(
            overrides: baseOverrides(auth: fakeAuth(), track: track),
          )
          ..listen(replayControllerProvider, (_, _) {})
          ..read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });
  ReplayController ctl() => c.read(replayControllerProvider.notifier);
  ReplayState? s() => c.read(replayControllerProvider);

  test('alone: plays a copy of your prints, 120 ms per print', () {
    ctl().start(own);
    expect(s()!.track, own);
    expect(s()!.clock, isFalse);
    expect(s()!.totalMs, 10000); // replayMs(3) floors at 10 s
    expect(s()!.playing, isTrue);
  });

  test(
    'with friends and a live range: everyone by the clock in about a minute',
    () {
      ctl().start(
        own,
        others: const [
          [TrackPoint(9, 9, 500), TrackPoint(9, 9, 3500)],
        ],
        live: true,
      );
      expect(s()!.clock, isTrue);
      expect(s()!.track.map((p) => p.t), [500, 3500]);
      expect(s()!.totalMs, 60000);
      expect(s()!.own, own);
      expect(s()!.clockAt, 500);
    },
  );

  test('friends but a past range: alone', () {
    ctl().start(
      own,
      others: const [
        [TrackPoint(9, 9, 500)],
      ],
    );
    expect(s()!.clock, isFalse);
  });

  test(
    'step moves along and stops at the end; toggle at the end starts over',
    () {
      ctl()
        ..start(own)
        ..step(5000);
      expect(s()!.pos, 1);
      ctl().step(60000);
      expect(s()!.pos, 2);
      expect(s()!.playing, isFalse);
      ctl().toggle();
      expect(s()!.pos, 0);
      expect(s()!.playing, isTrue);
    },
  );

  test('seek pauses; speed cycles 1 → 2 → 4 → 8 → 0.5 → 1', () {
    ctl()
      ..start(own)
      ..seek(1.5);
    expect(s()!.pos, 1.5);
    expect(s()!.playing, isFalse);
    final seen = <double>[];
    for (var i = 0; i < 5; i++) {
      ctl().cycleSpeed();
      seen.add(s()!.speed);
    }
    expect(seen, [2, 4, 8, 0.5, 1]);
  });

  test('a new range stops the replay; so does signing out', () async {
    ctl().start(own);
    c
        .read(trailControllerProvider.notifier)
        .setRange(presetRange(Preset.d7, DateTime.now()));
    expect(s(), isNull);
    ctl().start(own);
    await c.read(authControllerProvider.notifier).signOut();
    expect(s(), isNull);
  });
}
