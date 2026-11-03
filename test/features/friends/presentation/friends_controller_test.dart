import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
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
    when(repo.live).thenAnswer(
      (_) async => const [LivePoint(id: 'b', lat: 1, lon: 2, ts: 'T')],
    );
    when(() => repo.today(any())).thenAnswer(
      (_) async => (
        points: const [TrackPoint(2, 1, 100)],
        last: const LastPoint(lon: 2, lat: 1, ts: 'T0'),
      ),
    );
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

  test(
    'refreshes every 7 s; me fetched once; live only when someone is shown',
    () {
      fakeAsync((f) {
        start(f);
        expect(s().me?.friendCode, 'K7QM-3XPA');
        expect(s().relations, rel);
        f.elapse(const Duration(seconds: 14));
        verify(repo.relations).called(3);
        verify(repo.me).called(1);
        verifyNever(repo.live);
      });
    },
  );

  test('a shown friend: today on switch-on, then every 60 s; on the map in their colour', () {
    fakeAsync((f) {
      start(f);
      unawaited(c.read(friendsControllerProvider.notifier).toggle('b'));
      f.elapse(Duration.zero);
      verify(() => repo.today('b')).called(1);
      expect(prefs.shown, ['b']);
      final onMap = c.read(friendsOnMapProvider);
      expect(onMap.single.name, 'Bình');
      expect(onMap.single.points, const [TrackPoint(2, 1, 100)]);
      expect(onMap.single.last?.ts, 'T'); // live beats today's last
      f.elapse(const Duration(seconds: 60));
      verify(() => repo.today('b')).called(1);
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
      expect(s().live, isEmpty);
      expect(s().today, isEmpty);
    });
  });

  test('401 signs out; 403 means no account', () {
    fakeAsync((f) {
      start(f);
      when(repo.relations).thenThrow(const AuthExpired());
      f.elapse(const Duration(seconds: 7));
      expect(c.read(authControllerProvider), AuthPhase.signedOut);
    });
    fakeAsync((f) {
      start(f);
      when(repo.relations).thenThrow(const AccountMissing());
      f.elapse(const Duration(seconds: 7));
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
}
