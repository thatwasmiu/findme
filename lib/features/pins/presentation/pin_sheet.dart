import 'dart:async';

import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:findme/features/shares/presentation/shares_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

const _oops = 'Chưa làm được, thử lại sau chút nhé ✨';

/// One pin: its photos and videos, add more, send it to a friend, delete (PinSheet.tsx).
class PinSheet extends ConsumerStatefulWidget {
  const PinSheet({required this.pin, required this.onClose, super.key});

  final Pin pin;
  final VoidCallback onClose;

  @override
  ConsumerState<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<PinSheet> {
  double? _progress;
  String _err = '';
  String _note = '';

  PinsRepository get _repo => ref.read(pinsRepositoryProvider);
  Pin get _pin => widget.pin;
  String get _link =>
      _pin.shareCode == null ? '' : _repo.shareLink(_pin.shareCode!);

  void _refresh() =>
      unawaited(ref.read(pinsControllerProvider.notifier).refresh());

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _err = '');
    try {
      await fn();
      if (mounted) _refresh();
    } on Object {
      if (mounted) setState(() => _err = _oops);
    }
  }

  Future<void> _more() async {
    final List<PinFile> files;
    try {
      files = await ref.read(pinPickerProvider).gallery();
    } on Object {
      if (mounted) setState(() => _err = _oops);
      return;
    }
    if (files.isEmpty || !mounted) return;
    setState(() {
      _err = '';
      _progress = 0;
    });
    final r = await _repo.uploadAll(_pin.id, files, (f) {
      if (mounted) setState(() => _progress = f);
    });
    if (!mounted) return;
    setState(() {
      _progress = null;
      if (r.failed > 0) _err = r.message;
    });
    _refresh();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (mounted) setState(() => _note = 'Đã sao chép link 💖');
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: const Text(
          'Xoá hết ảnh và video của nơi này? Không lấy lại được đâu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _act(() async {
      await _repo.deletePin(_pin.id);
      if (mounted) widget.onClose();
    });
  }

  Future<void> _view(PinMedia m) => showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: const Color(0xE6000000),
    builder: (_) => _Viewer(m),
  );

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: CardBox(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pin.name ?? pinDate(_pin.createdAt),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Pill(
                    label: '✕',
                    style: PillStyle.ghost,
                    semanticLabel: 'Đóng',
                    onTap: widget.onClose,
                  ),
                ],
              ),
              Notice(
                '${pinDate(_pin.createdAt)} · ${_pin.media.length} ảnh/video',
              ),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                padding: EdgeInsets.zero, // or it adds the status bar's height
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final m in _pin.media)
                    _Tile(
                      label: m.isVideo ? 'Xem video' : 'Xem ảnh',
                      onTap: m.isReady ? () => _view(m) : null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (m.thumb == null)
                            const Center(child: Text('⏳'))
                          else
                            _Media(m.thumb!, fit: BoxFit.cover),
                          if (m.isVideo && m.thumb != null)
                            const Center(
                              child: Text(
                                '▶',
                                style: TextStyle(
                                  color: Colors.white,
                                  shadows: [Shadow(blurRadius: 4)],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  _Tile(
                    label: 'Thêm ảnh hoặc video',
                    onTap: _progress == null ? _more : null,
                    child: const Center(
                      child: Text(
                        '＋',
                        style: TextStyle(color: Palette.pink, fontSize: 22),
                      ),
                    ),
                  ),
                ],
              ),
              if (_progress != null)
                Semantics(
                  label: 'Đang tải lên',
                  child: LinearProgressIndicator(value: _progress),
                ),
              if (_pin.note != null) Text(_pin.note!),
              if (link.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(
                      label: 'Sao chép link',
                      style: PillStyle.on,
                      onTap: _copy,
                    ),
                    Pill(
                      label: 'Gửi',
                      onTap: () => ref.read(shareLauncherProvider)(
                        _pin.name ?? 'Find Me',
                        link,
                      ),
                    ),
                    Pill(
                      label: 'Tắt link',
                      style: PillStyle.ghost,
                      onTap: () => _act(() => _repo.unsharePin(_pin.id)),
                    ),
                  ],
                )
              else
                Pill(
                  label: '🔗 Gửi cho bạn',
                  style: PillStyle.on,
                  onTap: () => _act(() => _repo.sharePin(_pin.id)),
                ),
              if (_note.isNotEmpty) Notice(_note),
              Pill(label: '🗑️ Xoá', onTap: _remove),
              if (_err.isNotEmpty) Notice(_err, error: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(color: Palette.pinkSoft, child: child),
      ),
    ),
  );
}

/// A picture from Look Back, with the cookie that opens it.
class _Media extends ConsumerWidget {
  const _Media(this.mediaKey, {required this.fit});

  final String mediaKey;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(pinsRepositoryProvider);
    return Image.network(
      repo.mediaUrl(mediaKey),
      headers: repo.mediaHeaders,
      fit: fit,
      errorBuilder: (_, _, _) => const Center(child: Text('⏳')),
    );
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer(this.media);

  final PinMedia media;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(onTap: () => Navigator.maybePop(context)),
      ),
      Center(
        child: media.isVideo
            ? _PinVideo(media)
            : media.display == null
            ? const SizedBox()
            : _Media(media.display!, fit: BoxFit.contain),
      ),
      SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Pill(
              label: '✕',
              semanticLabel: 'Đóng',
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        ),
      ),
    ],
  );
}

/// HLS through the phone's own player; the cookie goes with the playlist and every segment.
class _PinVideo extends ConsumerStatefulWidget {
  const _PinVideo(this.media);

  final PinMedia media;

  @override
  ConsumerState<_PinVideo> createState() => _PinVideoState();
}

class _PinVideoState extends ConsumerState<_PinVideo> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final hls = widget.media.hls;
    if (hls == null) {
      _failed = true;
      return;
    }
    final repo = ref.read(pinsRepositoryProvider);
    final c = _c = VideoPlayerController.networkUrl(
      Uri.parse(repo.mediaUrl(hls)),
      httpHeaders: repo.mediaHeaders,
      formatHint: VideoFormat.hls,
    );
    unawaited(
      c.initialize().then(
        (_) {
          if (!mounted) return;
          setState(() {});
          unawaited(c.play());
        },
        onError: (Object _) {
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_c?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Notice('Chưa mở được — thử lại sau chút nhé ✨', error: true);
    }
    final c = _c!;
    if (!c.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          if (widget.media.thumb != null)
            _Media(widget.media.thumb!, fit: BoxFit.contain),
          const CircularProgressIndicator(color: Palette.pink),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() {
          unawaited(c.value.isPlaying ? c.pause() : c.play());
        }),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(c),
            VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Palette.pink),
            ),
          ],
        ),
      ),
    );
  }
}
