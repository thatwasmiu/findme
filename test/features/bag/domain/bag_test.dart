import 'package:findme/features/bag/domain/bag.dart';
import 'package:flutter_test/flutter_test.dart';

String? href(BagItem i) => switch (itemAction(i)) {
  OpenLink(:final href) => href,
  ShowInPlace() => null,
};

void main() {
  group('itemAction: what tapping a pocket does', () {
    test('calls, mails and opens links', () {
      expect(
        href(const BagItem(type: ItemType.phone, value: '090 123 4567')),
        'tel:0901234567',
      );
      expect(
        href(const BagItem(type: ItemType.zalo, value: '0901234567')),
        'https://zalo.me/0901234567',
      );
      expect(
        href(
          const BagItem(type: ItemType.zalo, value: 'https://zalo.me/g/abc'),
        ),
        'https://zalo.me/g/abc',
      );
      expect(
        href(const BagItem(type: ItemType.email, value: 'a@b.vn')),
        'mailto:a@b.vn',
      );
      expect(
        href(
          const BagItem(type: ItemType.youtube, value: 'https://youtu.be/x'),
        ),
        'https://youtu.be/x',
      );
    });

    test('shows pictures and notes in place', () {
      for (final t in [ItemType.qr, ItemType.photo, ItemType.note]) {
        expect(itemAction(BagItem(type: t)), isA<ShowInPlace>());
      }
    });
  });

  group('canAdd', () {
    final s = <BagItem?>[
      const BagItem(type: ItemType.phone, value: '1'),
      ...List.filled(7, null),
    ];
    test('allows once-only types once', () {
      expect(canAdd(s, ItemType.phone), isFalse);
      expect(canAdd(s, ItemType.link), isTrue);
    });
    test('refuses a full bag', () {
      expect(
        canAdd(
          List.filled(8, const BagItem(type: ItemType.note, value: 'x')),
          ItemType.link,
        ),
        isFalse,
      );
    });
  });

  test('repeatable types are exactly link, qr, photo, note', () {
    expect(
      [
        for (final t in itemTypes)
          if (t.repeat) t.type.name,
      ]..sort(),
      ['link', 'note', 'photo', 'qr'],
    );
    expect(itemTypes, hasLength(11));
  });

  test('avatarPath points at Look Back', () {
    expect(avatarPath('m1'), '/lb/api/findme/avatar/m1');
  });

  test('slotsFrom: always 8; unknown types and gaps are empty', () {
    final s = slotsFrom([
      {'type': 'qr', 'image': '/i', 'media': 'm'},
      null,
      {'type': 'fax', 'value': '1'},
    ]);
    expect(s, hasLength(8));
    expect((s[0]!.type, s[0]!.image, s[0]!.media), (ItemType.qr, '/i', 'm'));
    expect(s.skip(1), everyElement(isNull));
  });

  test('toSave: no image, no empty label, the receipt for a new picture', () {
    expect(
      const BagItem(
        type: ItemType.photo,
        label: '',
        image: '/i',
        media: 'm',
        receipt: 'R',
      ).toSave(),
      {'type': 'photo', 'media': 'm', 'receipt': 'R'},
    );
    expect(
      const BagItem(
        type: ItemType.link,
        value: 'https://x',
        label: 'Blog',
      ).toSave(),
      {'type': 'link', 'value': 'https://x', 'label': 'Blog'},
    );
  });

  group('cropSquare', () {
    test('the centred square of the short side', () {
      expect(cropSquare(1000, 500, 1, 0, 0), (sx: 250.0, sy: 0.0, side: 500.0));
    });
    test('zooming in takes a smaller square, still centred', () {
      expect(cropSquare(1000, 500, 2, 0, 0), (
        sx: 375.0,
        sy: 125.0,
        side: 250.0,
      ));
    });
    test('an offset never leaves the picture, at any corner', () {
      expect(cropSquare(1000, 500, 2, 9999, 9999), (
        sx: 750.0,
        sy: 250.0,
        side: 250.0,
      ));
      expect(cropSquare(1000, 500, 2, -9999, -9999), (
        sx: 0.0,
        sy: 0.0,
        side: 250.0,
      ));
      expect(cropSquare(1000, 500, 1, 0, 9999), (
        sx: 250.0,
        sy: 0.0,
        side: 500.0,
      ));
    });
  });
}
