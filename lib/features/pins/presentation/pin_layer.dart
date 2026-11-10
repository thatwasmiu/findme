import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Photo bubbles on the map, re-merged whenever the zoom changes (the web's PinLayer.ts).
class PinBubbles extends ConsumerWidget {
  const PinBubbles({
    required this.pins,
    required this.onOpen,
    required this.onZoomIn,
    super.key,
  });

  final List<Pin> pins;
  final void Function(Pin) onOpen;
  final void Function(LatLng at, double zoom) onZoomIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = MapCamera.of(context).zoom.round();
    return MarkerLayer(
      markers: [
        for (final b in mergePins(pins, zoom))
          Marker(
            point: LatLng(b.lat, b.lon),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => b.pins.length == 1
                  ? onOpen(b.pins.single)
                  : onZoomIn(
                      LatLng(b.lat, b.lon),
                      (zoom + 2).clamp(0, pinMaxZoom).toDouble(),
                    ),
              child: _bubble(b, ref.read(pinsRepositoryProvider)),
            ),
          ),
      ],
    );
  }

  Widget _bubble(Bubble b, PinsRepository repo) {
    final only = b.pins.length == 1 && b.pins.single.media.length == 1
        ? b.pins.single.media.single
        : null;
    return Semantics(
      button: true,
      label: 'Xem ảnh',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.pinkSoft,
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: b.thumb == null
                  ? const _Waiting()
                  : Image.network(
                      repo.mediaUrl(b.thumb!),
                      headers: repo.mediaHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _Waiting(),
                    ),
            ),
          ),
          if (only?.isVideo ?? false)
            const Center(
              child: Text(
                '▶',
                style: TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            ),
          if (b.count > 1)
            Positioned(
              top: -9,
              right: -9,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Palette.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${b.count}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 20 / 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('⏳', style: TextStyle(fontSize: 18)));
}
