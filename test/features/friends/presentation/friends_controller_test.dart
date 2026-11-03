import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

const bob = Friend(id: 'b', name: 'Bình', since: 'S');
const rel = Relations(friends: [bob]);

void main() {
  late MockFriends repo;
  late MemoryPrefs prefs;
  late ProviderContainer c;

  void start(FakeAsync f, {List<String> shown = const []}) {
    repo = MockFriends();
    prefs = MemoryPrefs()..shown = shown;
    when(
      repo.me,
    ).thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K7QM-3XPA'));
    when(repo.relations).thenAnswer((_) async => rel);
    c =
        ProviderContainer(
            overrides: baseOverrides(
              auth: fakeAuth(),
              friends: repo,
              prefs: prefs,
            ),
          )
          ..listen(friendsControllerProvider, (_, _) {})
          ..read(authControllerProvider);
    f.elapse(Duration.zero);
  }

  FriendsState s() => c.read(friendsControllerProvider);

  test('refreshes the list every 60 s; me fetched once', () {
    fakeAsync((f) {
      start(f);
      expect(s().me?.friendCode, 'K7QM-3XPA');
      expect(s().relations, rel);
      f.elapse(const Duration(seconds: 120));
      verify(repo.relations).called(3);
      verify(repo.me).called(1);
    });
  });

  test('ask / apply: what /track is asked for shown friends, and its answer '
      'on the map in their colour', () {
    fakeAsync((f) {
      final now = DateTime(2026, 10, 28, 15);
      final day = isoMs(DateTime(2026, 10, 28));
      start(f);
      final ctl = c.read(friendsControllerProvider.notifier);
      expect(ctl.ask(now), '');
      unawaited(ctl.toggle('b'));
      f.elapse(Duration.zero);
      expect(prefs.shown, ['b']);
      expect(ctl.ask(now), 'b~~');
      final s0 = DateTime.parse(day).millisecondsSinceEpoch ~/ 1000;
      const last = LastPoint(lon: 2, lat: 1, ts: 'T0');
      ctl.apply(
        [
          FriendPart(id: 'b', points: [TrackPoint(2, 1, s0 + 60)], last: last),
        ],
        'b~~',
        now,
      );
      final onMap = c.read(friendsOnMapProvider);
      expect(onMap.single.name, 'Bình');
      expect(onMap.single.points, [TrackPoint(2, 1, s0 + 60)]);
      expect(onMap.single.last, last);
      expect(ctl.ask(now), startsWith('b~$day~T0'));
      // Asked for but left out of the answer: no longer allowed to be seen. Not asked for: kept.
      ctl.restore({...s().today, 'x': (points: const [], last: null)});
      ctl.apply(const [], 'b~$day~T0', now);
      expect(s().today.keys, ['x']);
    });
  });

  test('a removed friend drops off the map though the id is still saved', () {
    fakeAsync((f) {
      start(f, shown: ['b', 'gone']);
      expect(c.read(friendsOnMapProvider).map((m) => m.id), ['b']);
    });
  });

  test('friends state cleared on sign out', () {
    fakeAsync((f) {
      start(f, shown: ['b']);
      expect(s().me, isNotNull);
      c.read(authControllerProvider.notifier).expired();
      f.elapse(Duration.zero);
      expect(s().me, isNull);
      expect(s().relations, Relations.empty);
      expect(s().today, isEmpty);
    });
  });

  test('401 signs out; 403 means no account', () {
    fakeAsync((f) {
      start(f);
      when(repo.relations).thenThrow(const AuthExpired());
      f.elapse(const Duration(seconds: 60));
      expect(c.read(authControllerProvider), AuthPhase.signedOut);
    });
    fakeAsync((f) {
      start(f);
      when(repo.relations).thenThrow(const AccountMissing());
      f.elapse(const Duration(seconds: 60));
      expect(c.read(authControllerProvider), AuthPhase.noAccount);
    });
  });

  test('send: "already friends" when they had asked you', () {
    fakeAsync((f) {
      start(f);
      when(() => repo.sendRequest(any()))
          .thenAnswer((_) async => (outgoing: null, friend: bob));
      String? note;
      unawaited(
        c
            .read(friendsControllerProvider.notifier)
            .send('x')
            .then((n) => note = n),
      );
      f.flushMicrotasks();
      expect(note, 'Bạn và Bình đã là bạn bè 🎉');
    });
  });

  test('sign out during the first load leaves no timers behind', () {
    fakeAsync((f) {
      final gate = Completer<Relations>();
      repo = MockFriends();
      prefs = MemoryPrefs();
      when(repo.me)
          .thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K'));
      when(repo.relations).thenAnswer((_) => gate.future);
      c =
          ProviderContainer(
              overrides: baseOverrides(
                auth: fakeAuth(),
                friends: repo,
                prefs: prefs,
              ),
            )
            ..listen(friendsControllerProvider, (_, _) {})
            ..read(authControllerProvider);
      f.elapse(Duration.zero);
      c.read(authControllerProvider.notifier).expired();
      f.elapse(Duration.zero);
      gate.complete(rel);
      f.elapse(const Duration(minutes: 3));
      expect(f.periodicTimerCount, 0);
      verify(repo.relations).called(1);
    });
  });

  test('back in the app: the list refreshes at once; paused does nothing', () {
    fakeAsync((f) {
      start(f);
      verify(repo.relations).called(1);
      c.read(friendsControllerProvider.notifier).paused();
      f.elapse(const Duration(minutes: 2));
      verifyNever(repo.relations);
      c.read(friendsControllerProvider.notifier).resumed();
      f.elapse(Duration.zero);
      verify(repo.relations).called(1);
    });
  });
}
