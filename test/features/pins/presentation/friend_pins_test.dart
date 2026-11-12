import 'dart:async';

import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/friend_pins_controller.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import 'pins_ui_test.dart' show FakeSignedIn, pin;

Pin of(String sub, [String id = 'p']) => pin(id: '$sub-$id', sub: sub);

void main() {
  test('visibleFriendPins keeps only friends shown on the map', () {
    final all = [of('a'), of('b'), of('a', 'q')];
    expect(visibleFriendPins(all, ['a']).map((p) => p.id), ['a-p', 'a-q']);
    expect(visibleFriendPins(all, const []), isEmpty);
  });

  test('grantDue: none yet, or less than a minute left', () {
    expect(grantDue(null, 100), isTrue);
    expect(grantDue(159, 100), isTrue);
    expect(grantDue(161, 100), isFalse);
  });

  group('FriendPinsController', () {
    late MockPins pins;
    late DateTime now;

    ProviderContainer container({int friends = 1}) {
      final c = ProviderContainer(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), pins: pins),
          authControllerProvider.overrideWith(FakeSignedIn.new),
          friendCountProvider.overrideWithValue(friends),
          nowProvider.overrideWithValue(() => now),
        ],
      );
      // Disposed by each test: the 5-minute timer must be gone before the test ends.
      c.listen(friendPinsControllerProvider, (_, _) {});
      return c;
    }

    int nowS() => now.millisecondsSinceEpoch ~/ 1000;

    setUp(() {
      now = DateTime.utc(2026, 11, 12, 10);
      pins = quietPins();
      when(pins.pinGrant)
          .thenAnswer((_) async => (grant: 'g', exp: nowS() + 900));
      when(() => pins.loadSharedPins(any())).thenAnswer((_) async => [of('a')]);
    });

    testWidgets('no friends: asks nothing', (t) async {
      final c = container(friends: 0);
      await t.pump();
      expect(c.read(friendPinsControllerProvider), isEmpty);
      verifyNever(pins.pinGrant);
      verifyNever(() => pins.loadSharedPins(any()));
      c.dispose();
    });

    testWidgets('loads now and every 5 minutes, reusing the pass', (t) async {
      final c = container();
      await t.pump();
      expect(c.read(friendPinsControllerProvider).single.sub, 'a');
      now = now.add(friendPinsRefresh);
      await t.pump(friendPinsRefresh);
      verify(() => pins.loadSharedPins('g')).called(2);
      verify(pins.pinGrant).called(1);
      // 14.5 minutes in: under a minute left on the pass, so a new one.
      now = now.add(const Duration(minutes: 9, seconds: 30));
      c.read(friendPinsControllerProvider.notifier).resumed();
      await t.pump();
      verify(pins.pinGrant).called(1);
      c.dispose();
    });

    testWidgets('no pass: no pins, Look Back not asked', (t) async {
      when(pins.pinGrant).thenAnswer((_) async => null);
      final c = container();
      await t.pump();
      expect(c.read(friendPinsControllerProvider), isEmpty);
      verifyNever(() => pins.loadSharedPins(any()));
      c.dispose();
    });

    testWidgets('paused: the timer asks nothing', (t) async {
      final c = container();
      await t.pump();
      c.read(friendPinsControllerProvider.notifier).paused();
      await t.pump(friendPinsRefresh);
      verify(() => pins.loadSharedPins(any())).called(1);
      c.dispose();
    });

    testWidgets('signing out empties them; a late answer cannot refill', (
      t,
    ) async {
      final gate = Completer<List<Pin>>();
      when(() => pins.loadSharedPins(any())).thenAnswer((_) => gate.future);
      final c = container();
      await t.pump();
      (c.read(authControllerProvider.notifier) as FakeSignedIn).leave();
      await t.pump();
      gate.complete([of('a')]);
      await t.pump();
      expect(c.read(friendPinsControllerProvider), isEmpty);
      c.dispose();
    });
  });
}
