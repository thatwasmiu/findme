import 'dart:math';

/// The bag: 8 pockets a person fills with ways to reach them (port of the web's `bag.ts`). The server validates
/// every item.
enum ItemType {
  phone,
  zalo,
  email,
  youtube,
  spotify,
  tiktok,
  instagram,
  link,
  qr,
  photo,
  note,
}

enum ItemInput { phone, email, url, image, text, phoneOrUrl }

typedef TypeInfo = ({ItemType type, String name, bool repeat, ItemInput input});

const List<TypeInfo> itemTypes = [
  (
    type: ItemType.phone,
    name: 'Số điện thoại',
    repeat: false,
    input: ItemInput.phone,
  ),
  (
    type: ItemType.zalo,
    name: 'Zalo',
    repeat: false,
    input: ItemInput.phoneOrUrl,
  ),
  (type: ItemType.email, name: 'Email', repeat: false, input: ItemInput.email),
  (
    type: ItemType.youtube,
    name: 'YouTube',
    repeat: false,
    input: ItemInput.url,
  ),
  (
    type: ItemType.spotify,
    name: 'Spotify',
    repeat: false,
    input: ItemInput.url,
  ),
  (type: ItemType.tiktok, name: 'TikTok', repeat: false, input: ItemInput.url),
  (
    type: ItemType.instagram,
    name: 'Instagram',
    repeat: false,
    input: ItemInput.url,
  ),
  (type: ItemType.link, name: 'Đường link', repeat: true, input: ItemInput.url),
  (type: ItemType.qr, name: 'Mã QR', repeat: true, input: ItemInput.image),
  (type: ItemType.photo, name: 'Ảnh', repeat: true, input: ItemInput.image),
  (
    type: ItemType.note,
    name: 'Thư bí mật',
    repeat: true,
    input: ItemInput.text,
  ),
];

TypeInfo typeInfo(ItemType t) => itemTypes.firstWhere((x) => x.type == t);

const slotCount = 8;

/// One pocket. [image]: a short-lived address of the picture (qr, photo), relative to the web origin. [media]: its
/// id, only in your own bag. [receipt]: Look Back's proof for a new picture, until the bag is saved.
class BagItem {
  const BagItem({
    required this.type,
    this.value,
    this.label,
    this.image,
    this.media,
    this.receipt,
  });

  /// null for a type this app does not know yet (a newer server): that pocket shows as empty.
  static BagItem? fromJson(Map<String, dynamic> j) {
    final t = ItemType.values.where((x) => x.name == j['type']).firstOrNull;
    if (t == null) return null;
    return BagItem(
      type: t,
      value: j['value'] as String?,
      label: j['label'] as String?,
      image: j['image'] as String?,
      media: j['media'] as String?,
    );
  }

  final ItemType type;
  final String? value;
  final String? label;
  final String? image;
  final String? media;
  final String? receipt;

  /// The label, or the type's name.
  String get title =>
      label != null && label!.isNotEmpty ? label! : typeInfo(type).name;

  BagItem copyWith({
    String? value,
    String? label,
    String? image,
    String? media,
    String? receipt,
  }) => BagItem(
    type: type,
    value: value ?? this.value,
    label: label ?? this.label,
    image: image ?? this.image,
    media: media ?? this.media,
    receipt: receipt ?? this.receipt,
  );

  /// What PUT /me/bag takes: no `image`, an empty label left out.
  Map<String, dynamic> toSave() => {
    'type': type.name,
    'value': ?value,
    if (label != null && label!.isNotEmpty) 'label': label,
    'media': ?media,
    'receipt': ?receipt,
  };
}

typedef Slots = List<BagItem?>;

/// Always [slotCount] long.
Slots slotsFrom(List<dynamic> raw) => [
  for (var i = 0; i < slotCount; i++)
    if (i < raw.length && raw[i] is Map<String, dynamic>)
      BagItem.fromJson(raw[i] as Map<String, dynamic>)
    else
      null,
];

/// What tapping a pocket does: open a link (tel:, mailto:, https:) or show the picture / note in place.
sealed class ItemAction {
  const ItemAction();
}

class OpenLink extends ItemAction {
  const OpenLink(this.href);
  final String href;
}

class ShowInPlace extends ItemAction {
  const ShowInPlace();
}

ItemAction itemAction(BagItem i) {
  final v = i.value ?? '';
  return switch (i.type) {
    ItemType.phone => OpenLink('tel:${v.replaceAll(RegExp(r'[^\d+]'), '')}'),
    ItemType.zalo => OpenLink(
      v.startsWith('https://')
          ? v
          : 'https://zalo.me/${v.replaceAll(RegExp(r'\D'), '')}',
    ),
    ItemType.email => OpenLink('mailto:$v'),
    ItemType.qr || ItemType.photo || ItemType.note => const ShowInPlace(),
    _ => OpenLink(v),
  };
}

/// Room left, and a once-only type not already in the bag.
bool canAdd(Slots slots, ItemType t) =>
    slots.any((s) => s == null) &&
    (typeInfo(t).repeat || !slots.any((s) => s?.type == t));

/// The avatar picture, relative to the web origin (public: the share page shows it without a login).
String avatarPath(String media) => '/lb/api/findme/avatar/$media';

/// The square of a w × h picture to keep for an avatar: the short side divided by [zoom] (≥ 1), centred, moved by
/// the offset (picture pixels) but never past an edge.
({double sx, double sy, double side}) cropSquare(
  double w,
  double h,
  double zoom,
  double ox,
  double oy,
) {
  final side = min(w, h) / max(1, zoom);
  double clamp(double v, double hi) => v.clamp(0, hi).toDouble();
  return (
    sx: clamp((w - side) / 2 + ox, w - side),
    sy: clamp((h - side) / 2 + oy, h - side),
    side: side,
  );
}
