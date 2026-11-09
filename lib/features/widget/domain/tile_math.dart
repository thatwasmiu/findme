import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show immutable;

const widgetZoom = 16;
const widgetSizePx = 400;
const tileSizePx = 256;

/// One OpenStreetMap tile.
@immutable
class TileKey {
  const TileKey(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is TileKey && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);
}

double _worldSize(int zoom) => ((1 << zoom) * tileSizePx).toDouble();

double _worldX(double lon, int zoom) => (lon + 180) / 360 * _worldSize(zoom);

/// Web Mercator. dart:math has no asinh.
double _worldY(double lat, int zoom) {
  final t = tan(lat * pi / 180);
  return (1 - log(t + sqrt(t * t + 1)) / pi) / 2 * _worldSize(zoom);
}

/// The tiles a square image of [sizePx] centred on this position touches.
// ponytail: no wrap at the 180th meridian; a widget there would miss tiles on one side.
Set<TileKey> tilesFor(
  double lat,
  double lon, {
  int zoom = widgetZoom,
  int sizePx = widgetSizePx,
}) {
  final half = sizePx / 2;
  final cx = _worldX(lon, zoom);
  final cy = _worldY(lat, zoom);
  final x0 = ((cx - half) / tileSizePx).floor();
  final x1 = ((cx + half) / tileSizePx).floor();
  final y0 = ((cy - half) / tileSizePx).floor();
  final y1 = ((cy + half) / tileSizePx).floor();
  return {
    for (var x = x0; x <= x1; x++)
      for (var y = y0; y <= y1; y++) TileKey(zoom, x, y),
  };
}

/// Where a position lands in the image, with ([centreLat], [centreLon]) in its middle.
Offset toImage(
  double lat,
  double lon, {
  required double centreLat,
  required double centreLon,
}) => Offset(
  widgetSizePx / 2 + _worldX(lon, widgetZoom) - _worldX(centreLon, widgetZoom),
  widgetSizePx / 2 + _worldY(lat, widgetZoom) - _worldY(centreLat, widgetZoom),
);

/// Where a tile lands in the image.
Rect tileRect(
  TileKey key, {
  required double centreLat,
  required double centreLon,
}) => Rect.fromLTWH(
  widgetSizePx / 2 + key.x * tileSizePx - _worldX(centreLon, key.z),
  widgetSizePx / 2 + key.y * tileSizePx - _worldY(centreLat, key.z),
  tileSizePx.toDouble(),
  tileSizePx.toDouble(),
);
