import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

Widget app(MockAuth auth) => ProviderScope(
  overrides: baseOverrides(auth: auth),
  child: MaterialApp(theme: buildTheme(), home: const WelcomeScreen()),
);

void main() {
  testWidgets('loading, then the welcome line and the form', (t) async {
    final gate = Completer<String?>();
    final auth = fakeAuth();
    when(auth.getAccessToken).thenAnswer((_) => gate.future);
    await t.pumpWidget(app(auth));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/logo.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Find Me'), findsOneWidget);
    expect(find.text('Đang khởi động…'), findsOneWidget);
    gate.complete(null);
    await t.pumpAndSettle();
    expect(
      find.text(
        'Mọi nơi bạn đã đi qua, gói gọn trong một tấm bản đồ xinh xắn.',
      ),
      findsOneWidget,
    );
    expect(find.text('Đăng nhập 💖'), findsOneWidget);
  });

  testWidgets(
    'wrong password shows the web message; busy label while waiting',
    (t) async {
      final auth = fakeAuth(token: null);
      final gate = Completer<void>();
      when(() => auth.login(any(), any())).thenAnswer((_) => gate.future);
      await t.pumpWidget(app(auth));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('email')), 'me@x.vn');
      await t.enterText(find.byKey(const Key('password')), 'pw');
      await t.tap(find.text('Đăng nhập 💖'));
      await t.pump();
      expect(find.text('Đang đăng nhập…'), findsOneWidget);
      gate.completeError(const AuthError('NotAuthorizedException'));
      await t.pumpAndSettle();
      expect(find.text('Sai email hoặc mật khẩu.'), findsOneWidget);
      verify(() => auth.login('me@x.vn', 'pw')).called(1);
    },
  );

  testWidgets('no account: points to the web admin page and offers sign out', (
    t,
  ) async {
    final auth = fakeAuth();
    await t.pumpWidget(app(auth));
    await t.pumpAndSettle();
    final c = ProviderScope.containerOf(t.element(find.byType(WelcomeScreen)));
    c.read(authControllerProvider.notifier).noAccount();
    await t.pumpAndSettle();
    expect(find.text(noAccountText), findsOneWidget);
    await t.tap(find.text('Đăng xuất'));
    await t.pumpAndSettle();
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
  });
}
