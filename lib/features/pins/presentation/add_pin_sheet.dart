import 'dart:async';

import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📷: a photo where you stand (AddPinSheet.tsx). Location first; refused or unknown means no pin.
class AddPinSheet extends ConsumerStatefulWidget {
  const AddPinSheet({
    required this.stops,
    required this.onSpot,
    required this.onAdded,
    required this.onClose,
    super.key,
  });

  final List<Stop> stops;

  /// Where you are: the map goes there.
  final void Function(double lat, double lon) onSpot;
  final VoidCallback onAdded;
  final VoidCallback onClose;

  @override
  ConsumerState<AddPinSheet> createState() => _AddPinSheetState();
}

class _AddPinSheetState extends ConsumerState<AddPinSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  Fix? _fix; // null = still looking
  bool _typed = false; // typing first wins over a late place name
  bool _naming = false; // asking Find Me for a name
  double? _progress;
  String _err = '';

  @override
  void initState() {
    super.initState();
    unawaited(_locate());
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _fix = null);
    final f = await ref.read(pinFixProvider)();
    if (!mounted) return;
    setState(() => _fix = f);
    if (f is! FixOk) return;
    widget.onSpot(f.lat, f.lon);
    final near = nameNear(widget.stops, f.lat, f.lon);
    if (near.isNotEmpty) {
      if (!_typed) _name.text = near;
      return;
    }
    // No stop with a name close by (e.g. tracking off): ask Find Me.
    setState(() => _naming = true);
    final found = await ref
        .read(pinsRepositoryProvider)
        .placeName(f.lat, f.lon);
    if (!mounted) return;
    setState(() {
      _naming = false;
      if (!_typed) _name.text = found;
    });
  }

  Future<void> _pick() async {
    final here = _fix;
    if (here is! FixOk) return;
    final List<PinFile> files;
    try {
      files = await ref.read(pinPickerProvider).photo();
    } on Object {
      if (mounted) setState(() => _err = uploadMessage(null, null));
      return;
    }
    if (files.isEmpty || !mounted) return;
    setState(() {
      _err = '';
      _progress = 0;
    });
    try {
      final r = await ref.read(pinsRepositoryProvider).addFiles(
        (
          lat: here.lat,
          lon: here.lon,
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
    final fix = _fix;
    final problem = fix == null ? null : geoMessage(fix);
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
                      'Chụp ảnh ở đây',
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
              if (fix == null) const Notice('Đang tìm vị trí của bạn… 📍'),
              if (problem != null) Notice(problem, error: true),
              if (fix is FixFailed)
                Pill(label: 'Thử lại', style: PillStyle.on, onTap: _locate),
              if (fix is FixOk) ...[
                TextField(
                  key: const Key('pinName'),
                  controller: _name,
                  enabled: !busy,
                  maxLength: 80,
                  onChanged: (_) => _typed = true,
                  decoration: InputDecoration(
                    hintText: _naming
                        ? 'Đang tìm tên nơi này…'
                        : 'Tên nơi này (không bắt buộc)',
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
                else
                  Pill(label: '📷 Chụp ảnh', style: PillStyle.on, onTap: _pick),
              ],
              if (_err.isNotEmpty) Notice(_err, error: true),
            ],
          ),
        ),
      ),
    );
  }
}
