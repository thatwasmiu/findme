import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter/material.dart';

/// The pastel tint over map tiles, shared by the app's map and the home-screen widget. Like the web's `.osm-tiles`
/// filter (approximation of saturate(0.6) sepia(0.15) brightness(1.05)).
const pastelMatrix = <double>[
  0.78, 0.26, 0.04, 0, 6, //
  0.12, 0.88, 0.04, 0, 6, //
  0.10, 0.22, 0.70, 0, 6, //
  0, 0, 0, 1, 0, //
];

/// Paints the prints on a canvas. Each print points toward the next one and steps alternately left/right.
/// [color]: one colour for every print (a friend's trail); else coloured by time of day.
void paintPaws(
  Canvas canvas,
  List<TrackPoint> points, {
  required Offset Function(TrackPoint) project,
  required Size area,
  required double size,
  Color? color,
}) {
  final paint = Paint();
  final glow = Paint()
    ..color = Colors.white.withValues(alpha: 0.9)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final at = project(p);
    if (at.dx < -20 ||
        at.dy < -20 ||
        at.dx > area.width + 20 ||
        at.dy > area.height + 20) {
      continue;
    }
    final next = i + 1 < points.length ? points[i + 1] : p;
    final prev = i > 0 ? points[i - 1] : p;
    final angle = next != p
        ? bearing(p, next)
        : (prev != p ? bearing(prev, p) : 0.0);
    final side = i.isOdd ? 1 : -1; // left, right, left, … like real footprints
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(angle)
      ..translate(side * size * 0.35, 0);
    _drawPaw(canvas, size, glow);
    paint.color = (color ?? pawColor(p.t)).withValues(alpha: 0.85);
    _drawPaw(canvas, size, paint);
    canvas.restore();
  }
}

/// One cat paw at (0,0), toes pointing up, about [s] px tall.
void _drawPaw(Canvas c, double s, Paint paint) {
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
