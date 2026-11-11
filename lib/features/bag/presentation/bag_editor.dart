import 'dart:async';
import 'dart:io';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/bag/presentation/avatar_crop.dart';
import 'package:findme/features/bag/presentation/bag_icons.dart';
import 'package:findme/features/bag/presentation/bag_widgets.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _placeholder = <ItemType, String>{
  ItemType.phone: '0901 234 567',
  ItemType.zalo: 'Số điện thoại hoặc link zalo.me',
  ItemType.email: 'ban@email.com',
  ItemType.youtube: 'https://youtube.com/…',
  ItemType.spotify: 'https://open.spotify.com/…',
  ItemType.tiktok: 'https://www.tiktok.com/@…',
  ItemType.instagram: 'https://www.instagram.com/…',
  ItemType.link: 'https://…',
  ItemType.note: 'Viết gì đó cho bạn bè nhé 💌',
};

const _whyCodes = {
  'twice': 'Mỗi loại này chỉ bỏ vào túi một lần thôi.',
  'receipt': 'Có ảnh chưa sẵn sàng, chọn lại ảnh đó nhé.',
  'label': 'Tên món dài quá (tối đa 20 chữ).',
  'phone': 'Số điện thoại chưa đúng.',
  'email': 'Email chưa đúng.',
  'note': 'Thư trống hoặc dài quá (tối đa 500 chữ).',
};

/// What to say when the server refuses the bag: by its code, or the item type whose link is wrong.
String whyBag(String code) {
  final known = _whyCodes[code];
  if (known != null) return known;
  final t = ItemType.values.where((x) => x.name == code).firstOrNull;
  return t != null
      ? '${typeInfo(t).name}: link chưa đúng (phải bắt đầu bằng https:// và đúng trang).'
      : 'Có món chưa đúng, kiểm tra lại nhé.';
}

/// Your own bag (the web's BagEditor.tsx): tap an empty pocket to add from the list, a full one to change, move or
/// remove it. Your avatar on top; tapping it changes it.
class BagEditor extends ConsumerStatefulWidget {
  const BagEditor({super.key});

  static Future<void> open(BuildContext context) =>
      showBagSheet(context, const BagEditor());

  @override
  ConsumerState<BagEditor> createState() => _BagEditorState();
}

class _BagEditorState extends ConsumerState<BagEditor> {
  Slots? _slots;
  Set<String> _saved = {}; // pictures in the stored bag
  int? _index; // the pocket being added to or edited
  BagItem? _draft; // null while choosing what to add
  final _value = TextEditingController();
  final _label = TextEditingController();
  final _local =
      <
        String,
        String
      >{}; // media id -> the file just picked, to show it before it is saved
  String _busy = '';
  String _err = '';
  String _note = '';
  bool _dirty = false;

  BagRepository get _repo => ref.read(bagRepositoryProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _value.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _repo.myBag();
      if (!mounted) return;
      setState(() {
        _slots = s;
        _saved = _mediaOf(s);
      });
    } on Object catch (e) {
      if (!_signedOut(e) && mounted) {
        setState(() => _err = 'Chưa mở được túi, thử lại sau nhé 🎒');
      }
    }
  }

  static Set<String> _mediaOf(Slots s) => {
    for (final i in s)
      if (i?.media != null) i!.media!,
  };

  bool _signedOut(Object e) {
    if (e is AuthExpired) {
      ref.read(authControllerProvider.notifier).expired();
      return true;
    }
    if (e is AccountMissing) {
      ref.read(authControllerProvider.notifier).noAccount();
      return true;
    }
    return false;
  }

  void _edit(int index, BagItem draft) => setState(() {
    _index = index;
    _draft = draft;
    _value.text = draft.value ?? '';
    _label.text = draft.label ?? '';
    _err = '';
  });

  void _back() => setState(() {
    _index = null;
    _draft = null;
  });

  void _put(int index, BagItem? item) => setState(() {
    _slots = [..._slots!]..[index] = item;
    _dirty = true;
    _note = '';
    _index = null;
    _draft = null;
  });

  void _swap(int a, int b) {
    if (b < 0 || b >= slotCount) return;
    setState(() {
      final n = [..._slots!];
      final t = n[a];
      n[a] = n[b];
      n[b] = t;
      _slots = n;
      _dirty = true;
      _index = null;
      _draft = null;
    });
  }

  Future<void> _pickPicture() async {
    final file = await ref.read(pinPickerProvider).image();
    if (file == null || !mounted) return;
    setState(() {
      _err = '';
      _busy = 'Đang tải ảnh lên… 0%';
    });
    try {
      final r = await _repo.uploadCard(
        file,
        'bag',
        (f) {
          if (mounted) {
            setState(() => _busy = 'Đang tải ảnh lên… ${(f * 100).round()}%');
          }
        },
        onProcessing: () {
          if (mounted) setState(() => _busy = 'Đang xử lý ảnh… ✨');
        },
      );
      _local[r.media] = file.path;
      if (mounted) {
        setState(
          () => _draft = _draft?.copyWith(media: r.media, receipt: r.receipt),
        );
      }
    } on Object catch (e) {
      if (mounted) setState(() => _err = cardErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _save() async {
    final slots = _slots;
    if (slots == null) return;
    setState(() {
      _err = '';
      _note = '';
      _busy = 'Đang cất vào túi…';
    });
    try {
      // Receipts last 10 minutes: new pictures get a fresh one now, however long the bag took to fill.
      final ready = await freshReceipts(slots, _saved, _repo.receipt);
      final b = await _repo.saveMyBag(ready);
      // Only after a successful save: pictures no longer in the bag leave Look Back.
      final now = _mediaOf(b);
      _saved.difference(now).forEach(_repo.deleteCard);
      // ponytail: a picture uploaded but never saved (closed without saving) stays in Look Back until the account
      // is removed; it only uses quota. Sweep pinless pictures nobody references if that ever matters.
      if (!mounted) return;
      setState(() {
        _saved = now;
        _slots = b;
        _dirty = false;
        _note = 'Đã cất vào túi 🎒✨';
      });
    } on Object catch (e) {
      if (!_signedOut(e) && mounted) {
        setState(
          () => _err = e is FriendError
              ? whyBag(e.code)
              : 'Chưa lưu được, thử lại nhé ✨',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<bool> _okToClose() async =>
      !_dirty ||
      (await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              content: const Text('Túi chưa được lưu. Đóng luôn nhé?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Thôi'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ) ??
          false);

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(friendsControllerProvider.select((s) => s.me));
    final notices = [
      if (_busy.isNotEmpty) Notice(_busy),
      if (_err.isNotEmpty) Notice(_err, error: true),
      if (_note.isNotEmpty) Notice(_note),
    ];
    final Widget body;
    if (_index != null && _draft == null) {
      body = _picker();
    } else if (_draft != null) {
      body = _form(notices);
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BagHead(
            lead: Semantics(
              button: true,
              label: 'Đổi ảnh đại diện',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => AvatarCrop.open(context),
                child: AvatarCircle(
                  media: me?.avatar,
                  fallback: Image.asset(
                    'assets/images/hachiware.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: 'Túi của tôi',
            sub: 'Bạn bè chạm vào bạn trên bản đồ sẽ thấy',
          ),
          if (_slots != null)
            BagGrid(
              slots: _slots!,
              editable: true,
              onTap: (i) => _slots![i] != null
                  ? _edit(i, _slots![i]!)
                  : setState(() => _index = i),
            )
          else if (_err.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Đang mở túi…', textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          ...notices,
          if (_slots != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Pill(
                  label: 'Lưu túi',
                  style: PillStyle.on,
                  onTap: !_dirty || _busy.isNotEmpty ? null : _save,
                ),
              ),
            ),
        ],
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_index != null) return _back(); // back leaves the picker / form
        if (await _okToClose() && context.mounted) Navigator.pop(context);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: body,
      ),
    );
  }

  Widget _picker() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BagHead(title: 'Thêm vào túi'),
      const SizedBox(height: 12),
      PocketGrid(
        children: [
          for (final t in itemTypes.where((t) => canAdd(_slots!, t.type)))
            Pocket(
              type: t.type,
              onTap: () => _edit(_index!, BagItem(type: t.type)),
            ),
        ],
      ),
    ],
  );

  Widget _form(List<Widget> notices) {
    final draft = _draft!;
    final index = _index!;
    final info = typeInfo(draft.type);
    final web = ref.watch(appConfigProvider).web;
    final local = _local[draft.media];
    final Widget input;
    if (info.input == ItemInput.image) {
      input = Column(
        children: [
          if (local != null)
            Image.file(File(local), height: 220, fit: BoxFit.contain)
          else if (draft.image != null)
            Image.network(
              '$web${draft.image}',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              label: '📷 ${draft.media != null ? 'Chọn ảnh khác' : 'Chọn ảnh'}',
              onTap: _busy.isEmpty ? _pickPicture : null,
            ),
          ),
        ],
      );
    } else {
      input = TextField(
        key: const Key('bag-value'),
        controller: _value,
        maxLength: 500,
        minLines: info.input == ItemInput.text ? 4 : 1,
        maxLines: info.input == ItemInput.text ? 8 : 1,
        keyboardType: switch (info.input) {
          ItemInput.phone => TextInputType.phone,
          ItemInput.email => TextInputType.emailAddress,
          ItemInput.url => TextInputType.url,
          ItemInput.text => TextInputType.multiline,
          _ => TextInputType.text,
        },
        autocorrect: info.input == ItemInput.text,
        decoration: InputDecoration(
          hintText: _placeholder[draft.type],
          counterText: '',
        ),
        onChanged: (_) => setState(() {}),
      );
    }
    final ready = info.input == ItemInput.image
        ? draft.media != null
        : _value.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BagHead(lead: BagIcon(draft.type), title: info.name),
        const SizedBox(height: 12),
        input,
        const SizedBox(height: 8),
        TextField(
          key: const Key('bag-label'),
          controller: _label,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Tên món (không bắt buộc)',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        ...notices,
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_slots![index] != null) ...[
              Pill(
                label: '◀',
                style: PillStyle.ghost,
                semanticLabel: 'Dời sang trái',
                onTap: () => _swap(index, index - 1),
              ),
              Pill(
                label: '▶',
                style: PillStyle.ghost,
                semanticLabel: 'Dời sang phải',
                onTap: () => _swap(index, index + 1),
              ),
              Pill(
                label: 'Bỏ khỏi túi',
                style: PillStyle.ghost,
                onTap: () => _put(index, null),
              ),
            ],
            Pill(
              label: 'Xong',
              style: PillStyle.on,
              onTap: _busy.isNotEmpty || !ready
                  ? null
                  : () => _put(
                      index,
                      BagItem(
                        type: draft.type,
                        value: info.input == ItemInput.image
                            ? null
                            : _value.text,
                        label: _label.text,
                        image: draft.image,
                        media: draft.media,
                        receipt: draft.receipt,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
