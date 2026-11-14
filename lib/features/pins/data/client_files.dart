import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// The small files of a photo, made on the phone so Look Back has nothing to process: the picture is ready the
/// moment its upload ends. `width` and `height` are the photo's own, as its header gives them.
typedef ClientFiles = ({
  Uint8List thumb,
  Uint8List display,
  String blurDataUrl,
  int width,
  int height,
});

/// Makes [ClientFiles] for the image file at a path. Throws when it can't: Look Back then does it, as before.
typedef ClientEncoder = Future<ClientFiles> Function(String path);

/// Look Back's own sizes (its `processing/image.ts`), which it checks these files against to the pixel.
const int displayEdge = 2048;
const int thumbEdge = 400;
const int _displayMaxBytes = 4 * 1024 * 1024;
const int _thumbMaxBytes = 300 * 1024;

/// The short edge to ask the encoder for, so the long edge of a [w] x [h] picture lands on [longEdge]. A picture
/// already within it keeps its size (never enlarged). The same for wide and tall, so it does not matter whether
/// the encoder measures before or after turning the picture upright.
int targetShort(int w, int h, int longEdge) {
  final long = math.max(w, h);
  final short = math.min(w, h);
  if (long <= longEdge) return short;
  return math.max(1, (short * longEdge / long).round());
}

/// Whether [made] is what Look Back accepts for [source]: its long edge is [longEdge], or the source's own when
/// that is smaller, within a pixel.
bool rightSize((int, int) made, (int, int) source, int longEdge) =>
    (math.max(made.$1, made.$2) -
            math.min(longEdge, math.max(source.$1, source.$2)))
        .abs() <=
    1;

/// A phone too slow for this: more than 150 ms per megapixel of the photo. Small pictures count as 2 MP, or the
/// encoder's fixed costs alone would make each of them "slow".
bool tooSlow(Duration took, int w, int h) =>
    took.inMilliseconds > math.max(2, w * h / 1e6) * 150;

Future<(int, int)> _sizeOf(ui.ImmutableBuffer buffer) async {
  final d = await ui.ImageDescriptor.encoded(buffer);
  final size = (d.width, d.height);
  d.dispose();
  buffer.dispose();
  return size;
}

bool _isWebp(Uint8List b) =>
    b.length > 12 &&
    ascii.decode(b.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
    ascii.decode(b.sublist(8, 12), allowInvalid: true) == 'WEBP';

Future<Uint8List> _webp(Uint8List from, int short, int quality) =>
    FlutterImageCompress.compressWithList(
      from,
      minWidth: short,
      minHeight: short,
      quality: quality,
      format: CompressFormat.webp,
    );

/// The real encoder: the platform's own codecs through `flutter_image_compress`, off the UI thread. Display at a
/// 2048 long edge, thumb at 400 from the display, a tiny blur from the thumb, all WebP. Every result is measured
/// before it is returned: one that Look Back would refuse is not sent at all.
// ponytail: the photo's size is its header's, not turned upright. Look Back reads the size from the original
// itself for every type Find Me sends, so these two numbers are only a courtesy.
Future<ClientFiles> encodeClientFiles(String path) async {
  final source = await _sizeOf(await ui.ImmutableBuffer.fromFilePath(path));
  final want = targetShort(source.$1, source.$2, displayEdge);
  final display = await FlutterImageCompress.compressWithFile(
    path,
    minWidth: want,
    minHeight: want,
    quality: 82,
    format: CompressFormat.webp,
  );
  if (display == null || !_isWebp(display)) {
    throw StateError('no WebP display');
  }
  final displaySize = await _sizeOf(
    await ui.ImmutableBuffer.fromUint8List(display),
  );
  if (!rightSize(displaySize, source, displayEdge) ||
      display.length > _displayMaxBytes) {
    throw StateError('display $displaySize for $source');
  }

  final thumb = await _webp(
    display,
    targetShort(displaySize.$1, displaySize.$2, thumbEdge),
    75,
  );
  final thumbSize = await _sizeOf(
    await ui.ImmutableBuffer.fromUint8List(thumb),
  );
  if (!_isWebp(thumb) ||
      !rightSize(thumbSize, displaySize, thumbEdge) ||
      thumb.length > _thumbMaxBytes) {
    throw StateError('thumb $thumbSize for $displaySize');
  }

  final blur = await _webp(thumb, 20, 40);
  if (!_isWebp(blur)) throw StateError('no WebP blur');
  return (
    thumb: thumb,
    display: display,
    blurDataUrl: 'data:image/webp;base64,${base64.encode(blur)}',
    width: source.$1,
    height: source.$2,
  );
}
