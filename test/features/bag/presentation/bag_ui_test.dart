import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/bag/presentation/bag_editor.dart';
import 'package:findme/features/bag/presentation/bag_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

class MockBag extends Mock implements BagRepository;

Slots eight(List<BagItem?> s) => [
  ...s,
  ...List<BagItem?>.filled(slotCount - s.length, null),
];

void main() {
  setUpAll(() => registerFallbackValue(<BagItem?>[]));

  Future<void> pump(WidgetTester t, Widget child, List<Override> more) async {
    tallView(t);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(auth: fakeAuth()),
          ...more,
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: child),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets("a friend's bag: a phone calls, a note opens in place", (
    t,
  ) async {
    final opened = <Uri>[];
    await pump(
      t,
      BagSheet(
        title: 'Túi của Mèo',
        load: () async => eight([
          const BagItem(type: ItemType.phone, value: '090 123'),
          const BagItem(type: ItemType.note, value: 'chào nhé', label: 'Thư'),
        ]),
      ),
      [
        linkOpenerProvider.overrideWithValue((u) async {
          opened.add(u);
          return true;
        }),
      ],
    );
    expect(find.text('2 món nhỏ xinh'), findsOneWidget);
    await t.tap(find.text('Số điện thoại'));
    expect(opened, [Uri.parse('tel:090123')]);
    await t.tap(find.text('Thư'));
    await t.pumpAndSettle();
    expect(find.text('chào nhé'), findsOneWidget);
    await t.tap(find.text('Chạm để đóng'));
    await t.pumpAndSettle();
    expect(find.text('chào nhé'), findsNothing);
  });

  testWidgets('an empty bag and one that will not open', (t) async {
    await pump(t, BagSheet(title: 'Túi', load: () async => eight([])), []);
    expect(find.text('Túi còn trống trơn ✨'), findsOneWidget);
    await pump(
      t,
      BagSheet(
        key: const Key('again'),
        title: 'Túi 2',
        load: () => Future.error(Exception('x')),
      ),
      [],
    );
    expect(
      find.text('Chưa mở được túi này, thử lại sau nhé 🎒'),
      findsOneWidget,
    );
  });

  testWidgets('your bag: add a phone, save, say so', (t) async {
    final repo = MockBag();
    when(repo.myBag).thenAnswer((_) async => eight([]));
    Slots? sent;
    when(() => repo.saveMyBag(any())).thenAnswer((i) async {
      sent = i.positionalArguments.first as Slots;
      return sent!;
    });
    await pump(t, const BagEditor(), [
      bagRepositoryProvider.overrideWithValue(repo),
    ]);
    expect(find.text('Túi của tôi'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Thêm vào túi').first);
    await t.pump();
    await t.tap(find.text('Số điện thoại'));
    await t.pump();
    await t.enterText(find.byKey(const Key('bag-value')), '0901 234 567');
    await t.pump();
    await t.tap(find.text('Xong'));
    await t.pump();
    // once-only: the phone is no longer offered
    await t.tap(find.bySemanticsLabel('Thêm vào túi').first);
    await t.pump();
    expect(find.text('Số điện thoại'), findsNothing);
    expect(find.text('Zalo'), findsOneWidget);
    await t.binding.handlePopRoute(); // Android back leaves the list first
    await t.pump();
    await t.tap(find.text('Lưu túi'));
    await t.pump();
    await t.pump();
    expect(sent!.first?.toSave(), {'type': 'phone', 'value': '0901 234 567'});
    expect(find.text('Đã cất vào túi 🎒✨'), findsOneWidget);
  });

  testWidgets('a refused bag says why', (t) async {
    final repo = MockBag();
    when(repo.myBag).thenAnswer(
      (_) async => eight([const BagItem(type: ItemType.link, value: 'x')]),
    );
    when(() => repo.saveMyBag(any())).thenThrow(const FriendError('link'));
    await pump(t, const BagEditor(), [
      bagRepositoryProvider.overrideWithValue(repo),
    ]);
    await t.tap(find.text('Đường link'));
    await t.pump();
    await t.tap(find.text('▶'));
    await t.pump();
    await t.tap(find.text('Lưu túi'));
    await t.pump();
    await t.pump();
    expect(
      find.text(
        'Đường link: link chưa đúng (phải bắt đầu bằng https:// và đúng trang).',
      ),
      findsOneWidget,
    );
  });

  test('whyBag: known codes, a type, anything else', () {
    expect(whyBag('twice'), 'Mỗi loại này chỉ bỏ vào túi một lần thôi.');
    expect(whyBag('zalo'), startsWith('Zalo: link chưa đúng'));
    expect(whyBag('??'), 'Có món chưa đúng, kiểm tra lại nhé.');
  });
}
