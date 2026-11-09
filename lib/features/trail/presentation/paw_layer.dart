import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/trail_painting.dart';
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

/// Thousands of paw prints in one painter (no widget per print). [color]: one colour for every print (a friend's trail); else coloured by time of day.
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
  void paint(Canvas canvas, Size size) => paintPaws(
    canvas,
    points,
    project: (p) => camera.latLngToScreenOffset(LatLng(p.lat, p.lon)),
    area: size,
    size: pawSize(camera.zoom),
    color: color,
  );

  @override
  bool shouldRepaint(_PawPainter old) =>
      old.camera != camera ||
      old.color != color ||
      !samePoints(old.points, points);
}
