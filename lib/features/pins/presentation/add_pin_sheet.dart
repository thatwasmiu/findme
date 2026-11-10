import 'dart:async';

import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📷: choose what, confirm where. The map stays draggable behind the sheet; the pin is its centre (AddPinSheet.tsx).
class AddPinSheet extends ConsumerStatefulWidget {
  const AddPinSheet({
    required this.stops,
    required this.last,
    required this.center,
    required this.onStart,
    required this.onAdded,
    required this.onClose,
    super.key,
  });

  final List<Stop> stops;
  final Spot? last;

  /// The map's centre: where the pin goes.
  final ValueNotifier<Spot> center;
  final void Function(double lat, double lon) onStart;
  final VoidCallback onAdded;
  final VoidCallback onClose;

  @override
  ConsumerState<AddPinSheet> createState() => _AddPinSheetState();
}

class _AddPinSheetState extends ConsumerState<AddPinSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  bool _typed = false; // once typed, the map no longer renames it
  double? _progress;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _nameFromMap();
    widget.center.addListener(_nameFromMap);
    unawaited(_goToStart());
  }

  @override
  void dispose() {
    widget.center.removeListener(_nameFromMap);
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _nameFromMap() {
    if (_typed) return;
    final c = widget.center.value;
    _name.text = nameNear(widget.stops, c.lat, c.lon);
  }

  Future<void> _goToStart() async {
    final geo = await ref.read(pinGpsProvider)();
    if (!mounted) return;
    final s = startPosition(geo, widget.last, widget.center.value);
    widget.onStart(s.lat, s.lon);
  }

  Future<void> _pick(Future<List<PinFile>> Function() pick) async {
    final List<PinFile> files;
    try {
      files = await pick();
    } on Object {
      if (mounted) setState(() => _err = uploadMessage(null, null));
      return;
    }
    if (files.isEmpty || !mounted) return;
    setState(() {
      _err = '';
      _progress = 0;
    });
    final c = widget.center.value;
    try {
      final r = await ref.read(pinsRepositoryProvider).addFiles(
        (
          lat: c.lat,
          lon: c.lon,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
        files,
        (f) {
          if (mounted) setState(() => _progress = f);
        },
      );
      if (!mounted) return;
      if (r.pin != null && r.failed == 0) return widget.onAdded();
      setState(
        () => _err = r.pin != null
            ? '${r.failed} file chưa tải lên được. ${r.message}'
            : r.message,
      );
      if (r.pin != null) {
        Timer(const Duration(milliseconds: 2500), () {
          if (mounted) widget.onAdded();
        });
      }
    } on Object {
      if (mounted) setState(() => _err = uploadMessage(null, null));
    }
    if (mounted) setState(() => _progress = null);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _progress != null;
    final picker = ref.read(pinPickerProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.42,
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
                  const Expanded(
                    child: Text(
                      'Thêm vào nơi này',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Pill(
                    label: '✕',
                    style: PillStyle.ghost,
                    semanticLabel: 'Đóng',
                    onTap: busy ? null : widget.onClose,
                  ),
                ],
              ),
              const Notice('Kéo bản đồ để chỉnh vị trí 📍'),
              TextField(
                key: const Key('pinName'),
                controller: _name,
                enabled: !busy,
                maxLength: 80,
                onChanged: (_) => _typed = true,
                decoration: const InputDecoration(
                  hintText: 'Tên nơi này',
                  counterText: '',
                ),
              ),
              TextField(
                key: const Key('pinNote'),
                controller: _note,
                enabled: !busy,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Ghi chú (không bắt buộc)',
                  counterText: '',
                ),
              ),
              if (busy)
                Semantics(
                  label: 'Đang tải lên',
                  child: LinearProgressIndicator(value: _progress),
                )
              else ...[
                Pill(
                  label: '📷 Chụp ảnh',
                  style: PillStyle.on,
                  onTap: () => _pick(picker.photo),
                ),
                Pill(label: '🎥 Quay video', onTap: () => _pick(picker.video)),
                Pill(
                  label: '🖼️ Chọn từ máy',
                  onTap: () => _pick(picker.gallery),
                ),
              ],
              if (_err.isNotEmpty) Notice(_err, error: true),
            ],
          ),
        ),
      ),
    );
  }
}
