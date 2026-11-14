import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:findme/features/pins/data/client_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The real encoder on a real device or emulator: the platform's codecs decide the exact pixel sizes, and Look Back
/// refuses anything off by more than a pixel. Unit tests cannot show this (they have no codecs).
///
/// flutter test integration_test/client_files_test.dart --flavor dev --dart-define-from-file=config/example.json
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<(int, int)> sizeOf(Uint8List bytes) async {
    final d = await ui.ImageDescriptor.encoded(
      await ui.ImmutableBuffer.fromUint8List(bytes),
    );
    return (d.width, d.height);
  }

  /// A PNG of that size with something in it (stripes), written to a temp file.
  Future<String> picture(int w, int h) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (var i = 0; i < 40; i++) {
      canvas.drawRect(
        ui.Rect.fromLTWH(i * w / 40, 0, w / 40, h.toDouble()),
        ui.Paint()..color = ui.Color.fromARGB(255, i * 6, 255 - i * 6, 120),
      );
    }
    final image = await recorder.endRecording().toImage(w, h);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${Directory.systemTemp.path}/cf_${w}x$h.png');
    await file.writeAsBytes(png!.buffer.asUint8List());
    return file.path;
  }

  for (final (w, h, display, thumb) in [
    (4000, 3000, (2048, 1536), (400, 300)),
    (3000, 4000, (1536, 2048), (300, 400)),
    (4032, 3024, (2048, 1536), (400, 300)),
    (1920, 1080, (1920, 1080), (400, 225)),
    (300, 200, (300, 200), (300, 200)),
    (3001, 1999, (2048, 1364), (400, 266)),
  ]) {
    testWidgets('$w x $h -> display $display, thumb $thumb, all WebP', (
      _,
    ) async {
      final f = await encodeClientFiles(await picture(w, h));
      final d = await sizeOf(f.display);
      final t = await sizeOf(f.thumb);
      // Within a pixel, which is what Look Back allows.
      expect(
        (d.$1 - display.$1).abs() <= 1 && (d.$2 - display.$2).abs() <= 1,
        isTrue,
        reason: 'display $d',
      );
      expect(
        (t.$1 - thumb.$1).abs() <= 1 && (t.$2 - thumb.$2).abs() <= 1,
        isTrue,
        reason: 'thumb $t',
      );
      expect((f.width, f.height), (w, h));
      expect(String.fromCharCodes(f.display.sublist(8, 12)), 'WEBP');
      expect(String.fromCharCodes(f.thumb.sublist(8, 12)), 'WEBP');
      expect(f.blurDataUrl, startsWith('data:image/webp;base64,'));
      expect(f.blurDataUrl.length, lessThan(20000));
      expect(f.display.length, lessThan(4 * 1024 * 1024));
      expect(f.thumb.length, lessThan(300 * 1024));
    });
  }
}
