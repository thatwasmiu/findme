import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/bag/presentation/bag_widgets.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

const double _view = 220; // the round preview
const _out = 800; // the uploaded square, pixels

/// Pick a picture, slide and zoom it inside the circle, and it becomes your character on the map (the web's
/// AvatarCrop.tsx).
class AvatarCrop extends ConsumerStatefulWidget {
  const AvatarCrop({super.key});

  static Future<void> open(BuildContext context) =>
      showBagSheet(context, const AvatarCrop());

  @override
  ConsumerState<AvatarCrop> createState() => _AvatarCropState();
}

class _AvatarCropState extends ConsumerState<AvatarCrop> {
  ui.Image? _img;
  double _zoom = 1;
  Offset _off = Offset.zero;
  String _busy = '';
  String _err = '';

  ({double sx, double sy, double side})? get _crop => _img == null
      ? null
      : cropSquare(
          _img!.width.toDouble(),
          _img!.height.toDouble(),
          _zoom,
          _off.dx,
          _off.dy,
        );

  @override
  void dispose() {
    _img?.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    // Big enough for an 800 px circle at 3× zoom, small enough to decode quickly.
    final f = await ref.read(pinPickerProvider).image(maxSide: 2400);
    if (f == null || !mounted) return;
    try {
      final codec = await ui.instantiateImageCodec(
        await File(f.path).readAsBytes(),
      );
      final img = (await codec.getNextFrame()).image;
      if (!mounted) return img.dispose();
      setState(() {
        _img?.dispose();
        _img = img;
        _zoom = 1;
        _off = Offset.zero;
        _err = '';
      });
    } on Object {
      if (mounted) {
        setState(() => _err = 'Không mở được ảnh này, thử ảnh khác nhé.');
      }
    }
  }

  /// Dragging moves the picture under the circle: screen pixels → picture pixels, clamped by cropSquare.
  void _move(DragUpdateDetails d) {
    final img = _img;
    final c = _crop;
    if (img == null || c == null) return;
    final k = c.side / _view;
    final w = img.width.toDouble();
    final h = img.height.toDouble();
    final next = cropSquare(
      w,
      h,
      _zoom,
      _off.dx - d.delta.dx * k,
      _off.dy - d.delta.dy * k,
    );
    setState(
      () => _off = Offset(
        next.sx - (w - next.side) / 2,
        next.sy - (h - next.side) / 2,
      ),
    );
  }

  Future<void> _run(Future<String?> Function(BagRepository) work) async {
    setState(() => _err = '');
    final repo = ref.read(bagRepositoryProvider);
    final current = ref.read(friendsControllerProvider).me?.avatar;
    try {
      final avatar = await work(repo);
      if (current != null && current != avatar) repo.deleteCard(current);
      ref.read(friendsControllerProvider.notifier).setAvatar(avatar);
      if (mounted) Navigator.pop(context);
    } on AuthExpired {
      ref.read(authControllerProvider.notifier).expired();
    } on AccountMissing {
      ref.read(authControllerProvider.notifier).noAccount();
    } on Object catch (e) {
      if (mounted) setState(() => _err = cardErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _save() => _run((repo) async {
    final img = _img;
    final c = _crop;
    if (img == null || c == null) {
      throw const CardError('Chọn một tấm ảnh trước nhé.');
    }
    setState(() => _busy = 'Đang tải ảnh lên…');
    final rec = ui.PictureRecorder();
    Canvas(rec).drawImageRect(
      img,
      Rect.fromLTWH(c.sx, c.sy, c.side, c.side),
      const Rect.fromLTWH(0, 0, _out + 0.0, _out + 0.0),
      Paint()..filterQuality = FilterQuality.high,
    );
    final square = await rec.endRecording().toImage(_out, _out);
    // ponytail: PNG (Flutter has no JPEG encoder built in), ~1 MB against the web's ~100 KB JPEG; Look Back makes
    // its own display copy. Add an encoder package if upload time on slow networks matters.
    final bytes = await square.toByteData(format: ui.ImageByteFormat.png);
    square.dispose();
    if (bytes == null) throw const CardError('Không xử lý được ảnh này.');
    final file = File('${(await getTemporaryDirectory()).path}/avatar.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    final r = await repo.uploadCard(
      PinFile(file.path, 'avatar.png'),
      'avatar',
      (_) {},
      onProcessing: () {
        if (mounted) setState(() => _busy = 'Đang xử lý ảnh… ✨');
      },
    );
    if (mounted) setState(() => _busy = 'Sắp xong…');
    return await repo.setAvatar(r.receipt);
  });

  Future<void> _clear() {
    setState(() => _busy = 'Đang bỏ ảnh…');
    return _run((repo) => repo.setAvatar(null));
  }

  @override
  Widget build(BuildContext context) {
    final has = ref.watch(
      friendsControllerProvider.select((s) => s.me?.avatar != null),
    );
    final img = _img;
    final c = _crop;
    final ring = BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFFFD9D2),
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Palette.pink, spreadRadius: 3)],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BagHead(title: 'Ảnh đại diện trên bản đồ'),
          const SizedBox(height: 16),
          Container(
            width: _view,
            height: _view,
            decoration: ring,
            clipBehavior: Clip.antiAlias,
            child: img == null || c == null
                ? const Center(
                    child: Text('🙂', style: TextStyle(fontSize: 72)),
                  )
                : GestureDetector(
                    onPanUpdate: _move,
                    child: CustomPaint(painter: _CropPainter(img, c)),
                  ),
          ),
          if (img != null) ...[
            Row(
              children: [
                const Text('🔍'),
                Expanded(
                  child: Semantics(
                    label: 'Phóng to',
                    child: Slider(
                      value: _zoom,
                      min: 1,
                      max: 3,
                      onChanged: (z) => setState(() => _zoom = z),
                    ),
                  ),
                ),
              ],
            ),
            const Notice('Kéo ảnh để chỉnh vị trí trong vòng tròn'),
          ],
          const SizedBox(height: 10),
          Pill(
            label: '📷 ${img != null ? 'Chọn ảnh khác' : 'Chọn ảnh'}',
            onTap: _busy.isEmpty ? _choose : null,
          ),
          if (_busy.isNotEmpty) Notice(_busy),
          if (_err.isNotEmpty) Notice(_err, error: true),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (has)
                Pill(
                  label: 'Bỏ ảnh, dùng lại Hachiware',
                  style: PillStyle.ghost,
                  onTap: _busy.isEmpty ? _clear : null,
                ),
              Pill(
                label: 'Lưu ảnh',
                style: PillStyle.on,
                onTap: img == null || _busy.isNotEmpty ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.img, this.c);

  final ui.Image img;
  final ({double sx, double sy, double side}) c;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    img,
    Rect.fromLTWH(c.sx, c.sy, c.side, c.side),
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.medium,
  );

  @override
  bool shouldRepaint(_CropPainter old) => old.img != img || old.c != c;
}
