import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/widget/data/render.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> solidPng(Color color, int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

Future<int> pixel(ui.Image image, int x, int y) async {
  final data = (await image.toByteData())!;
  final o = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(o + 3),
    data.getUint8(o),
    data.getUint8(o + 1),
    data.getUint8(o + 2),
  ).toARGB32();
}

void main() {
  const here = TrackPoint(0, 0, 1800000000);
  const scene = WidgetScene(trail: [here], here: here);
  final page = Palette.page.toARGB32();
  const pureRed = 0xFFFF0000;

  testWidgets('the picture is 400x400', (tester) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      final image = await decode(await renderWidgetPng(scene, const {}, cat));
      expect(image.width, 400);
      expect(image.height, 400);
    });
  });

  testWidgets('a missing tile leaves Palette.page', (tester) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      final image = await decode(await renderWidgetPng(scene, const {}, cat));
      expect(await pixel(image, 0, 0), page);
    });
  });

  testWidgets('a tile is drawn with the pastel tint', (tester) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      final red = await solidPng(const Color(pureRed), 256);
      final tiles = {for (final k in tilesFor(0, 0)) k: red};
      final image = await decode(await renderWidgetPng(scene, tiles, cat));
      final corner = await pixel(image, 0, 0);
      expect(corner, isNot(pureRed));
      expect(corner, isNot(page));
    });
  });

  testWidgets('a damaged tile is skipped', (tester) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      final bad = Uint8List.fromList([1, 2, 3]);
      final tiles = {for (final k in tilesFor(0, 0)) k: bad};
      final image = await decode(await renderWidgetPng(scene, tiles, cat));
      expect(await pixel(image, 0, 0), page);
    });
  });

  testWidgets('an empty trail still draws Hachiware', (tester) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      final image = await decode(
        await renderWidgetPng(
          const WidgetScene(trail: [], here: here),
          const {},
          cat,
        ),
      );
      expect(await pixel(image, 200, 170), 0xFF000000);
    });
  });

  testWidgets('a trail point far outside the image does not throw', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cat = await solidPng(Colors.black, 8);
      const far = TrackPoint(50, 50, 1800000000);
      final png = await renderWidgetPng(
        const WidgetScene(trail: [far, here], here: here),
        const {},
        cat,
      );
      expect(png, isNotEmpty);
    });
  });
}
