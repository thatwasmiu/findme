import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/shares/domain/share.dart';
import 'package:findme/features/shares/presentation/shares_sheet.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

final now = DateTime(2026, 10, 28, 15);
final live = Share(
  id: 'a' * 22,
  label: 'Mẹ',
  createdAt: isoMs(now.subtract(const Duration(hours: 1))),
  expiresAt: isoMs(now.add(const Duration(minutes: 25))),
);
final old = Share(
  id: 'b' * 22,
  label: 'Ba',
  createdAt: isoMs(now.subtract(const Duration(days: 3))),
  expiresAt: isoMs(now.subtract(const Duration(days: 1))),
);

void main() {
  late MockShares repo;
  late List<(String, String)> shared;
  String? clipboard;

  setUp(() {
    repo = MockShares();
    shared = [];
    clipboard = null;
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });

  Future<void> pump(WidgetTester t, List<Share> list) async {
    when(repo.list).thenAnswer((_) async => list);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), shares: repo),
          nowProvider.overrideWithValue(() => now),
          shareLauncherProvider.overrideWithValue(
            (text, url) async => shared.add((text, url)),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: SharesSheet()),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('empty list', (t) async {
    await pump(t, []);
    expect(find.text('Chưa có link nào.'), findsOneWidget);
  });

  testWidgets('create: preset expiry, route off by default, note', (t) async {
    await pump(t, []);
    when(
      () => repo.create(
        label: any(named: 'label'),
        expiresAt: any(named: 'expiresAt'),
        route: any(named: 'route'),
        routeFrom: any(named: 'routeFrom'),
      ),
    ).thenAnswer((_) async => live);
    await t.enterText(find.byKey(const Key('label')), ' Mẹ ');
    await t.tap(find.text('1 giờ'));
    await t.tap(find.text('Tạo link 💖'));
    await t.pumpAndSettle();
    verify(
      () => repo.create(
        label: 'Mẹ',
        expiresAt: isoMs(now.add(const Duration(hours: 1))),
        routeFrom: any(named: 'routeFrom'),
      ),
    ).called(1);
    expect(find.text('Đã tạo link ✨ — bấm Sao chép để gửi.'), findsOneWidget);
    expect(find.text('Mẹ'), findsOneWidget);
  });

  testWidgets('a refused label shows the web wording', (t) async {
    await pump(t, []);
    when(
      () => repo.create(
        label: any(named: 'label'),
        expiresAt: any(named: 'expiresAt'),
        route: any(named: 'route'),
        routeFrom: any(named: 'routeFrom'),
      ),
    ).thenThrow(const ShareInvalid('label'));
    await t.enterText(find.byKey(const Key('label')), 'x');
    await t.tap(find.text('Tạo link 💖'));
    await t.pumpAndSettle();
    expect(find.text('Tên cần từ 1 đến 40 ký tự nhé.'), findsOneWidget);
  });

  testWidgets('copy and send use the web link', (t) async {
    await pump(t, [live]);
    expect(find.text('còn 25 phút · tạo 28/10 14:00'), findsOneWidget);
    await t.tap(find.text('Sao chép'));
    await t.pumpAndSettle();
    expect(clipboard, 'https://findme.test/s/${'a' * 22}');
    expect(find.text('Đã sao chép link cho "Mẹ" 💖'), findsOneWidget);
    await t.tap(find.text('Gửi'));
    expect(shared.single, (
      'Vị trí của mình (Mẹ)',
      'https://findme.test/s/${'a' * 22}',
    ));
  });

  testWidgets('revoke asks first', (t) async {
    await pump(t, [live]);
    when(() => repo.revoke(any())).thenAnswer((_) async {});
    await t.tap(find.text('Thu hồi').last);
    await t.pumpAndSettle();
    expect(
      find.text('Thu hồi link của "Mẹ"? Người đó sẽ không xem được nữa.'),
      findsOneWidget,
    );
    await t.tap(find.widgetWithText(TextButton, 'Thu hồi'));
    await t.pumpAndSettle();
    verify(() => repo.revoke(live.id)).called(1);
    expect(find.text('Chưa có link nào.'), findsOneWidget);
  });

  testWidgets(
    'expired share: no copy/send, Gia hạn and Xoá; extend for 7 days',
    (t) async {
      await pump(t, [old]);
      expect(find.textContaining('đã hết hạn'), findsOneWidget);
      expect(find.text('Sao chép'), findsNothing);
      expect(find.text('Gửi'), findsNothing);
      expect(find.text('Xoá'), findsOneWidget);
      when(
        () => repo.edit(
          any(),
          expiresAt: any(named: 'expiresAt'),
          route: any(named: 'route'),
          routeFrom: any(named: 'routeFrom'),
        ),
      ).thenAnswer(
        (_) async =>
            old.copyWith(expiresAt: isoMs(now.add(const Duration(days: 7)))),
      );
      await t.tap(find.text('Gia hạn'));
      await t.pumpAndSettle();
      await t.tap(find.text('7 ngày').last);
      await t.pumpAndSettle();
      verify(
        () => repo.edit(
          old.id,
          expiresAt: isoMs(now.add(const Duration(days: 7))),
        ),
      ).called(1);
      expect(find.text('Đã gia hạn "Ba" thêm 7 ngày ✨'), findsOneWidget);
    },
  );

  test('shareLink drops a trailing slash', () {
    expect(shareLink(testConfig, 'x'), 'https://findme.test/s/x');
  });

  testWidgets('closing the sheet while a call is running does not crash', (
    t,
  ) async {
    final gate = Completer<List<Share>>();
    when(repo.list).thenAnswer((_) => gate.future);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), shares: repo),
          nowProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: SharesSheet()),
        ),
      ),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), shares: repo),
          nowProvider.overrideWithValue(() => now),
        ],
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    gate.completeError(const AuthExpired());
    await t.pump();
  });
}
