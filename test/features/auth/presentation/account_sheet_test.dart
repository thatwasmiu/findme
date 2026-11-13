import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/auth/presentation/account_sheet.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

void main() {
  late MockFriends repo;

  Future<ProviderContainer> pump(WidgetTester t, {bool owner = false}) async {
    tallView(t);
    repo = MockFriends();
    when(repo.me).thenAnswer(
      (_) async => Me(name: 'Đạt', friendCode: 'K7QM-3XPA', owner: owner),
    );
    when(repo.relations).thenAnswer((_) async => Relations.empty);
    when(repo.deleteMe).thenAnswer((_) async {});
    await t.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(auth: fakeAuth(), friends: repo),
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: AccountSheet()),
        ),
      ),
    );
    final c = ProviderScope.containerOf(t.element(find.byType(AccountSheet)))
      ..read(authControllerProvider);
    await t.pump();
    await t.pump();
    await t.pump();
    return c;
  }

  Future<void> confirmWith(WidgetTester t, String name) async {
    await t.tap(find.text('🗑️ Xoá tài khoản'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('confirmName')), name);
    await t.tap(find.text('Xoá'));
    await t.pump();
    await t.pump();
  }

  testWidgets('bag, sign out and delete in one place', (t) async {
    await pump(t);
    expect(find.text('👤 Đạt'), findsOneWidget);
    expect(find.text('🎒 Túi của tôi & ảnh đại diện'), findsOneWidget);
    expect(find.text('👋 Đăng xuất'), findsOneWidget);
    expect(find.text('🗑️ Xoá tài khoản'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the owner account has no delete button', (t) async {
    await pump(t, owner: true);
    expect(find.text('🗑️ Xoá tài khoản'), findsNothing);
    expect(find.text('Tài khoản chủ không xoá được.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a name that does not match deletes nothing', (t) async {
    await pump(t);
    await confirmWith(t, 'Ai đó');
    expect(
      find.text('Tên chưa khớp, tài khoản vẫn còn nguyên.'),
      findsOneWidget,
    );
    verifyNever(repo.deleteMe);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the right name deletes the account, then signs out', (t) async {
    final c = await pump(t);
    await confirmWith(t, ' Đạt ');
    verify(repo.deleteMe).called(1);
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a delete that fails says to try again; still signed in', (
    t,
  ) async {
    final c = await pump(t);
    when(repo.deleteMe).thenThrow(const HttpError(504));
    await confirmWith(t, 'Đạt');
    expect(
      find.text('Chưa xoá xong (nhiều dữ liệu quá), bấm xoá lại lần nữa nhé.'),
      findsOneWidget,
    );
    expect(c.read(authControllerProvider), isNot(AuthPhase.signedOut));
    await t.pumpWidget(const SizedBox());
  });
}
