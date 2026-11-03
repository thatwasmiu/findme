import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/friends/presentation/friends_sheet.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

final now = DateTime(2026, 10, 28, 15);

void main() {
  late MockFriends repo;

  Future<void> pump(WidgetTester t, Relations rel) async {
    tallView(t);
    repo = MockFriends();
    when(
      repo.me,
    ).thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K7QM-3XPA'));
    when(repo.relations).thenAnswer((_) async => rel);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), friends: repo),
          nowProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: FriendsSheet()),
        ),
      ),
    );
    ProviderScope.containerOf(t.element(find.byType(FriendsSheet)))
        .read(authControllerProvider);
    await t.pump();
    await t.pump();
    await t.pump();
  }

  tearDown(() async {
    // let the periodic timers die with the widget tree
  });

  testWidgets('code, empty list, send a request', (t) async {
    await pump(t, Relations.empty);
    expect(find.text('K7QM-3XPA'), findsOneWidget);
    expect(
      find.text('Phiên bản dev'),
      findsOneWidget,
    ); // no APP_VERSION in tests
    expect(
      find.text('Chưa có bạn nào. Gửi mã của bạn cho người thân nhé.'),
      findsOneWidget,
    );
    when(() => repo.sendRequest(any()))
        .thenAnswer((_) async => (outgoing: null, friend: null));
    await t.enterText(find.byKey(const Key('code')), 'k7qm 3xpa');
    await t.tap(find.text('Gửi lời mời'));
    await t.pump();
    await t.pump();
    expect(find.text('Đã gửi lời mời 💌'), findsOneWidget);
    when(() => repo.sendRequest(any())).thenThrow(const FriendError('self'));
    await t.enterText(find.byKey(const Key('code')), 'mine');
    await t.tap(find.text('Gửi lời mời'));
    await t.pump();
    expect(find.text('Đây là mã của bạn mà 😄'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('incoming, friends (seen / not seen today), outgoing', (t) async {
    await pump(
      t,
      Relations(
        incoming: const [Pending(id: 'i', name: 'Lan', at: 'A')],
        friends: [
          Friend(
            id: 'b',
            name: 'Bình',
            since: 'S',
            lastTs: isoMs(now.subtract(const Duration(hours: 3))),
          ),
          const Friend(id: 'c', name: 'Chi', since: 'S'),
        ],
        outgoing: const [Pending(id: 'o', name: 'Minh', at: 'A')],
      ),
    );
    expect(find.text('Lời mời đến'), findsOneWidget);
    expect(find.text('muốn làm bạn với bạn'), findsOneWidget);
    expect(find.text('Bạn bè (2)'), findsOneWidget);
    expect(find.text('thấy 3 giờ trước'), findsOneWidget);
    expect(find.text('chưa thấy hôm nay'), findsOneWidget);
    expect(find.text('Đang chờ'), findsOneWidget);
    when(() => repo.answer(any(), accept: any(named: 'accept')))
        .thenAnswer((_) async {});
    await t.tap(find.text('Đồng ý'));
    await t.pump();
    await t.pump();
    expect(find.text('Bạn và Lan đã là bạn bè 🎉'), findsOneWidget);
    when(() => repo.remove(any())).thenAnswer((_) async {});
    await t.tap(find.text('Huỷ'));
    await t.pump();
    await t.pump();
    expect(find.text('Đã huỷ lời mời.'), findsOneWidget);
    await t.tap(find.text('Xoá bạn').first);
    await t.pumpAndSettle();
    expect(
      find.text('Xoá Bình khỏi bạn bè? Hai bạn sẽ không thấy nhau nữa.'),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
  });

  test(
    'fallback for DateRange mocks',
    () => registerFallbackValue(const DateRange(from: '', to: '')),
  );
}
