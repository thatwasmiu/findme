import 'package:findme/app.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/shares/domain/share.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fakes.dart';

/// The whole app with fake data: sign in → map with the day diary → open share links → sign out.
void main() {
  setUpAll(() => registerFallbackValue(const DateRange(from: '', to: '')));

  testWidgets('sign in, see the day, open shares, sign out', (t) async {
    final now = DateTime(2026, 10, 28, 15);
    final auth = fakeAuth(token: null);
    when(() => auth.login(any(), any())).thenAnswer((_) async {
      when(auth.getAccessToken).thenAnswer((_) async => 't');
    });
    final track = MockTrack();
    final s = now.millisecondsSinceEpoch ~/ 1000;
    when(() => track.fetch(any())).thenAnswer(
      (_) async => Track(
        points: [
          TrackPoint(105.78, 21.03, s - 600),
          TrackPoint(105.79, 21.04, s - 60),
        ],
        last: LastPoint(lon: 105.79, lat: 21.04, ts: isoMs(now)),
      ),
    );
    final shares = MockShares();
    when(shares.list).thenAnswer((_) async => <Share>[]);
    final friends = MockFriends();
    when(
      friends.me,
    ).thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K7QM-3XPA'));
    when(friends.relations).thenAnswer((_) async => Relations.empty);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(
            auth: auth,
            track: track,
            shares: shares,
            friends: friends,
          ),
          nowProvider.overrideWithValue(() => now),
        ],
        child: const FindMeApp(showTiles: false),
      ),
    );
    await t.pump();
    await t.enterText(find.byKey(const Key('email')), 'me@x.vn');
    await t.enterText(find.byKey(const Key('password')), 'pw');
    await t.tap(find.text('Đăng nhập 💖'));
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.text('📍 Find Me'), findsOneWidget);
    expect(find.text('📅 Nhật ký ngày'), findsOneWidget);
    expect(find.text('👀 vừa xong'), findsOneWidget);

    await t.tap(find.text('🔗 Chia sẻ'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('🔗 Chia sẻ vị trí'), findsOneWidget);
    await t.tap(find.text('✕'));
    await t.pump(const Duration(milliseconds: 500));

    await t.tap(find.bySemanticsLabel('Đăng xuất'));
    await t.pump();
    await t.pump();
    expect(find.text('Đăng nhập 💖'), findsOneWidget);
    expect(find.text('📍 Find Me'), findsNothing);
    await t.pumpWidget(const SizedBox()); // stop the polling timers
  });

  testWidgets('an open sheet closes when the session expires', (t) async {
    final track = MockTrack();
    when(() => track.fetch(any())).thenAnswer((_) async => Track.empty);
    final shares = MockShares();
    when(shares.list).thenAnswer(
      (_) async => [
        Share(id: 'a' * 22, label: 'Mẹ', createdAt: isoMs(DateTime(2026)), expiresAt: isoMs(DateTime(2099))),
      ],
    );
    final friends = MockFriends();
    when(friends.me).thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K'));
    when(friends.relations).thenAnswer((_) async => Relations.empty);
    await t.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(auth: fakeAuth(), track: track, shares: shares, friends: friends),
        child: const FindMeApp(showTiles: false),
      ),
    );
    await t.pump();
    await t.pump();
    await t.tap(find.text('🔗 Chia sẻ'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Mẹ'), findsOneWidget);
    ProviderScope.containerOf(t.element(find.byType(FindMeApp))).read(authControllerProvider.notifier).expired();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Mẹ'), findsNothing);
    expect(find.text('Đăng nhập 💖'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
