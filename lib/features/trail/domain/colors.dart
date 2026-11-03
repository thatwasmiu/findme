import 'dart:math';
import 'dart:ui';

import 'package:findme/features/trail/domain/models.dart';

// Friends' colours: none of them is one of pawColor's, so your own prints always look like yours.
const _friendColors = [
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
  Color(0xFF84CC16),
  Color(0xFF0891B2),
  Color(0xFFA855F7),
  Color(0xFF64748B),
];

/// A stable colour for one friend, from their id (same hash as the web, so the same colour there).
Color friendColor(String id) {
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return _friendColors[h % _friendColors.length];
}

/// Paw colour by the local hour: peach morning, pink afternoon, coral evening, lavender night.
Color pawColor(int epochSec) {
  final h = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000).hour;
  if (h >= 5 && h < 11) return const Color(0xFFFB923C);
  if (h >= 11 && h < 17) return const Color(0xFFEC4899);
  if (h >= 17 && h < 21) return const Color(0xFFF43F5E);
  return const Color(0xFF8B5CF6);
}

/// Compass bearing in radians (0 = north, clockwise), flat geometry (fine at street scale).
double bearing(TrackPoint a, TrackPoint b) {
  final dx = (b.lon - a.lon) * cos(a.lat * pi / 180);
  final dy = b.lat - a.lat;
  return atan2(dx, dy);
}

double distanceM(({double lat, double lon}) a, ({double lat, double lon}) b) {
  const rad = pi / 180;
  final dLat = (b.lat - a.lat) * rad;
  final dLon = (b.lon - a.lon) * rad;
  final h =
      pow(sin(dLat / 2), 2) +
      cos(a.lat * rad) * cos(b.lat * rad) * pow(sin(dLon / 2), 2);
  return 2 * 6371000 * asin(sqrt(h));
}
