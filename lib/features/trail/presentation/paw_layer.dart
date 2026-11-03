import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Paw size in px for a zoom level: smaller paws when zoomed out.
double pawSize(num zoom) => zoom >= 17
    ? 14
    : zoom >= 15
    ? 11
    : zoom >= 13
    ? 8
    : 6;

/// Polls hand us a fresh copy of the same trail every few seconds: redrawing thousands of prints for nothing costs
/// battery. ponytail: "same" = same length, same first and last print; a change elsewhere waits for the next one.
bool samePoints(List<TrackPoint> a, List<TrackPoint> b) =>
    identical(a, b) ||
    (a.length == b.length &&
        (a.isEmpty ||
            (a.first.t == b.first.t &&
                a.last.t == b.last.t &&
                a.last.lon == b.last.lon &&
                a.last.lat == b.last.lat)));

/// The print nearest to a screen point, within [maxPx].
TrackPoint? nearestPrint(
  List<TrackPoint> pts,
  Offset tap,
  Offset Function(TrackPoint) project, {
  double maxPx = 14,
}) {
  TrackPoint? best;
  var bestD = maxPx;
  for (final p in pts) {
    final d = (project(p) - tap).distance;
    if (d < bestD) {
      best = p;
      bestD = d;
    }
  }
  return best;
}

/// Thousands of paw prints in one painter (no widget per print). Each print points toward the next one and steps
/// alternately left/right. [color]: one colour for every print (a friend's trail); else coloured by time of day.
class PawLayer extends StatelessWidget {
  const PawLayer({required this.points, super.key, this.color});

  final List<TrackPoint> points;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context); // rebuilds on every pan/zoom
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PawPainter(points, color, camera),
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.points, this.color, this.camera);

  final List<TrackPoint> points;
  final Color? color;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    final s = pawSize(camera.zoom);
    final paint = Paint();
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final at = camera.latLngToScreenOffset(LatLng(p.lat, p.lon));
      if (at.dx < -20 ||
          at.dy < -20 ||
          at.dx > size.width + 20 ||
          at.dy > size.height + 20) {
        continue;
      }
      final next = i + 1 < points.length ? points[i + 1] : p;
      final prev = i > 0 ? points[i - 1] : p;
      final angle = next != p
          ? bearing(p, next)
          : (prev != p ? bearing(prev, p) : 0.0);
      final side = i.isOdd
          ? 1
          : -1; // left, right, left, … like real footprints
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(angle)
        ..translate(side * s * 0.35, 0);
      _drawPaw(canvas, s, glow);
      paint.color = (color ?? pawColor(p.t)).withValues(alpha: 0.85);
      _drawPaw(canvas, s, paint);
      canvas.restore();
    }
  }

  /// One cat paw at (0,0), toes pointing up, about [s] px tall.
  static void _drawPaw(Canvas c, double s, Paint paint) {
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.18),
          width: s * 0.6,
          height: s * 0.48,
        ),
      ); // main pad
    for (final (x, y, r) in const [
      (-0.3, -0.12, 0.11),
      (-0.11, -0.3, 0.12),
      (0.11, -0.3, 0.12),
      (0.3, -0.12, 0.11),
    ]) {
      path.addOval(
        Rect.fromCircle(center: Offset(x * s, y * s), radius: r * s),
      ); // toe beans
    }
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PawPainter old) =>
      old.camera != camera ||
      old.color != color ||
      !samePoints(old.points, points);
}
