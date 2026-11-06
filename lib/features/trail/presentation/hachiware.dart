import 'dart:math' as math;

import 'package:findme/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// The web's `.me` marker (travel-heatmap `web/src/styles.css`): Hachiware in a pink-ringed, glowing circle,
/// hopping on the spot every 1.6 s, a shadow that shrinks as she jumps and a pink ripple when she lands.
/// 56 × 66, feet (the shadow) at the bottom centre. Still when the phone asks for reduced motion.
class Hachiware extends StatefulWidget {
  const Hachiware({required this.label, super.key});

  final String label;

  @override
  State<Hachiware> createState() => _HachiwareState();
}

class _HachiwareState extends State<Hachiware>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    image: true,
    child: SizedBox(
      width: 56,
      height: 66,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, _) {
          final t = _loop.value;
          final hop = hopAt(t);
          final shadow = shadowAt(t);
          final ripple = rippleAt(t);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ripple on the ground
              Positioned(
                left: 13,
                bottom: 2,
                child: Opacity(
                  opacity: ripple.opacity,
                  child: Transform.scale(
                    scale: ripple.scale,
                    child: Container(
                      width: 30,
                      height: 12,
                      decoration: const ShapeDecoration(
                        shape: OvalBorder(
                          side: BorderSide(color: Palette.pink, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // shadow under her feet
              Positioned(
                left: 16,
                bottom: 3,
                child: Opacity(
                  opacity: shadow.opacity,
                  child: Transform.scale(
                    scale: shadow.scale,
                    child: Container(
                      width: 24,
                      height: 8,
                      decoration: const ShapeDecoration(
                        color: Color(0x403F2A3A), // rgba(63, 42, 58, 0.25)
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                ),
              ),
              // Hachiware, scaled and turned around her feet (transform-origin 50% 100%)
              Positioned(
                left: 4,
                bottom: 10,
                child: Transform(
                  key: const Key('hachiware-hop'),
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.translationValues(0, hop.dy, 0)
                    ..rotateZ(hop.turnDeg * math.pi / 180)
                    ..scaleByDouble(hop.sx, hop.sy, 1, 1),
                  child: Container(
                    key: const Key('hachiware-face'),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Palette.pink, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x73EC4899), // rgba(236, 72, 153, 0.45)
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/hachiware.webp',
                        fit: BoxFit.cover,
                        alignment: const Alignment(
                          0,
                          -0.3,
                        ), // object-position 50% 35%
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

typedef Hop = ({double dy, double sx, double sy, double turnDeg});
typedef Fade = ({double scale, double opacity});

/// `@keyframes hop`, eased in-out between stops like CSS `ease-in-out`.
Hop hopAt(double t) {
  const stops = <(double, Hop)>[
    (0, (dy: 0, sx: 1.06, sy: 0.94, turnDeg: 0)), // squish on landing
    (0.15, (dy: 0, sx: 1, sy: 1, turnDeg: 0)),
    (0.45, (dy: -12, sx: 0.97, sy: 1.04, turnDeg: -4)),
    (0.60, (dy: -12, sx: 0.97, sy: 1.04, turnDeg: 4)),
    (0.85, (dy: 0, sx: 1, sy: 1, turnDeg: 0)),
    (1, (dy: 0, sx: 1.06, sy: 0.94, turnDeg: 0)),
  ];
  final (a, b, f) = _segment(stops, t, Curves.easeInOut);
  return (
    dy: _lerp(a.dy, b.dy, f),
    sx: _lerp(a.sx, b.sx, f),
    sy: _lerp(a.sy, b.sy, f),
    turnDeg: _lerp(a.turnDeg, b.turnDeg, f),
  );
}

/// `@keyframes shadow`.
Fade shadowAt(double t) {
  const stops = <(double, Fade)>[
    (0, (scale: 1, opacity: 1)),
    (0.15, (scale: 1, opacity: 1)),
    (0.45, (scale: 0.6, opacity: 0.5)),
    (0.60, (scale: 0.6, opacity: 0.5)),
    (0.85, (scale: 1, opacity: 1)),
    (1, (scale: 1, opacity: 1)),
  ];
  return _fade(stops, t, Curves.easeInOut);
}

/// `@keyframes ripple` (ease-out).
Fade rippleAt(double t) {
  const stops = <(double, Fade)>[
    (0, (scale: 0.6, opacity: 0)),
    (0.80, (scale: 0.6, opacity: 0)),
    (0.85, (scale: 0.8, opacity: 0.9)),
    (1, (scale: 2.4, opacity: 0)),
  ];
  return _fade(stops, t, Curves.easeOut);
}

Fade _fade(List<(double, Fade)> stops, double t, Curve c) {
  final (a, b, f) = _segment(stops, t, c);
  return (
    scale: _lerp(a.scale, b.scale, f),
    opacity: _lerp(a.opacity, b.opacity, f),
  );
}

/// The two keyframes around [t] and how far between them, with [curve] applied per segment (as CSS does).
(T, T, double) _segment<T>(List<(double, T)> stops, double t, Curve curve) {
  final x = t.clamp(0.0, 1.0);
  for (var i = 1; i < stops.length; i++) {
    final (t0, v0) = stops[i - 1];
    final (t1, v1) = stops[i];
    if (x <= t1) {
      final span = t1 - t0;
      return (v0, v1, span <= 0 ? 1 : curve.transform((x - t0) / span));
    }
  }
  final last = stops.last.$2;
  return (last, last, 1);
}

double _lerp(double a, double b, double f) => a + (b - a) * f;
