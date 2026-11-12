import 'dart:math';

import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/models.dart';

/// One photo or video of a pin. [thumb], [display] and [hls] are keys under `/lb/media/`.
class PinMedia {
  const PinMedia({
    required this.id,
    required this.kind,
    required this.status,
    this.thumb,
    this.display,
    this.hls,
    this.shared = false,
  });

  factory PinMedia.fromJson(Map<String, dynamic> j) => PinMedia(
    id: j['id'] as String,
    kind: j['kind'] as String,
    status: j['status'] as String,
    thumb: j['thumb'] as String?,
    display: j['display'] as String?,
    hls: j['hls'] as String?,
    shared: j['shared'] == true,
  );

  final String id;
  final String kind; // image | video
  final String status; // processing | ready
  final String? thumb;
  final String? display;
  final String? hls;

  /// "Chia sẻ" on: friends and links with "Ảnh" see it.
  final bool shared;

  bool get isVideo => kind == 'video';
  bool get isReady => status == 'ready';
}

/// A place with photos (the web's `Pin`, stored by Look Back).
class Pin {
  const Pin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.createdAt,
    required this.media,
    this.name,
    this.note,
    this.sub,
  });

  factory Pin.fromJson(Map<String, dynamic> j) => Pin(
    id: j['id'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    name: j['name'] as String?,
    note: j['note'] as String?,
    createdAt: j['createdAt'] as String,
    sub: j['sub'] as String?,
    media: [
      for (final m in j['media'] as List<dynamic>? ?? const <dynamic>[])
        PinMedia.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final double lat;
  final double lon;
  final String? name;
  final String? note;
  final String createdAt;

  /// Whose pin, when it is a friend's shared one; null = yours.
  final String? sub;
  final List<PinMedia> media;
}

/// `10/11/2026`, like the web's `toLocaleDateString('vi-VN')`.
String pinDate(String iso) {
  final d = DateTime.parse(iso).toLocal();
  return '${d.day}/${d.month}/${d.year}';
}

typedef Spot = ({double lat, double lon});

const _nameNearM = 100.0;

/// The nearest named stop within 100 m: a starting name for a pin.
String nameNear(List<Stop> stops, double lat, double lon) {
  var best = '';
  var bestM = _nameNearM;
  for (final s in stops) {
    final m = distanceM((lat: s.lat, lon: s.lon), (lat: lat, lon: lon));
    if (s.name != null && s.name!.isNotEmpty && m <= bestM) {
      best = s.name!;
      bestM = m;
    }
  }
  return best;
}

/// The map's own limit: nothing merges here, so every pin stays tappable.
const pinMaxZoom = 19;
const _cellPx = 64;

class Bubble {
  const Bubble({
    required this.lat,
    required this.lon,
    required this.pins,
    required this.count,
    this.thumb,
  });

  final double lat;
  final double lon;
  final List<Pin> pins;
  final int count;
  final String? thumb;
}

double _worldPx(int zoom) => 256.0 * pow(2, zoom);
double _x(double lon, int zoom) => (lon + 180) / 360 * _worldPx(zoom);
double _y(double lat, int zoom) {
  final r = lat * pi / 180;
  return (1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * _worldPx(zoom);
}

/// Pins close together on screen become one bubble.
List<Bubble> mergePins(List<Pin> pins, int zoom) {
  final cells = <String, List<Pin>>{};
  for (final (i, p) in pins.indexed) {
    final key = zoom >= pinMaxZoom
        ? '$i'
        : '${(_x(p.lon, zoom) / _cellPx).floor()}:${(_y(p.lat, zoom) / _cellPx).floor()}';
    (cells[key] ??= []).add(p);
  }
  return [
    for (final group in cells.values)
      Bubble(
        lat: group.fold<double>(0, (s, p) => s + p.lat) / group.length,
        lon: group.fold<double>(0, (s, p) => s + p.lon) / group.length,
        pins: group,
        count: group.fold(0, (s, p) => s + p.media.length),
        thumb: group
            .expand((p) => p.media)
            .where((m) => m.isReady && m.thumb != null)
            .firstOrNull
            ?.thumb,
      ),
  ];
}
