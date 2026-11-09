import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/trail/presentation/paw_layer.dart';
import 'package:findme/features/trail/presentation/trail_painting.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/material.dart';

const _hachiwareHeight = 56.0;

/// The widget's picture: pastel map, paw trail, Hachiware on the latest spot, and OpenStreetMap's credit.
Future<Uint8List> renderWidgetPng(
  WidgetScene scene,
  Map<TileKey, Uint8List> tiles,
  Uint8List hachiware,
) async {
  final here = scene.here;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final area = Size.square(widgetSizePx.toDouble());
  canvas.drawRect(Offset.zero & area, Paint()..color = Palette.page);

  final tint = Paint()
    ..colorFilter = const ColorFilter.matrix(pastelMatrix);
  for (final MapEntry(:key, :value) in tiles.entries) {
    final image = await _decode(value);
    if (image == null) continue; // a damaged tile stays page colour
    final at = tileRect(key, centreLat: here.lat, centreLon: here.lon);
    canvas.drawImage(image, at.topLeft, tint);
    image.dispose();
  }

  paintPaws(
    canvas,
    scene.trail,
    project: (p) =>
        toImage(p.lat, p.lon, centreLat: here.lat, centreLon: here.lon),
    area: area,
    size: pawSize(widgetZoom),
  );

  final spot = toImage(
    here.lat,
    here.lon,
    centreLat: here.lat,
    centreLon: here.lon,
  );
  canvas.drawCircle(
    spot.translate(0, -_hachiwareHeight / 2),
    34,
    Paint()
      ..color = Palette.pink.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  final cat = await _decode(hachiware);
  if (cat != null) {
    final width = _hachiwareHeight * cat.width / cat.height;
    // Her feet stand on the point, as on the app's map.
    final to = Rect.fromLTWH(
      spot.dx - width / 2,
      spot.dy - _hachiwareHeight,
      width,
      _hachiwareHeight,
    );
    final from = Offset.zero & Size(cat.width.toDouble(), cat.height.toDouble());
    canvas.drawImageRect(
      cat,
      from,
      to,
      Paint()..filterQuality = FilterQuality.medium,
    );
    cat.dispose();
  }

  _paintCredit(canvas, area);

  final picture = recorder.endRecording();
  final image = await picture.toImage(widgetSizePx, widgetSizePx);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

/// The map's licence requires this to stay visible.
void _paintCredit(Canvas canvas, Size area) {
  final text = TextPainter(
    text: const TextSpan(
      text: '© OpenStreetMap',
      style: TextStyle(fontSize: 10, color: Palette.ink),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final at = Offset(
    area.width - text.width - 6,
    area.height - text.height - 4,
  );
  canvas.drawRect(
    (at & text.size).inflate(2),
    Paint()..color = Colors.white.withValues(alpha: 0.6),
  );
  text.paint(canvas, at);
  text.dispose();
}

Future<ui.Image?> _decode(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Object {
    return null;
  }
}
