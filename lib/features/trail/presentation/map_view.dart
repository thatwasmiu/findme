import 'dart:async';
import 'dart:math';

import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:findme/features/trail/presentation/paw_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Hà Nội (Hoàn Kiếm): where the map opens until this phone has seen a last point.
const home = LatLng(21.0285, 105.8542);

/// A friend shown on your map: their colour, today's prints, where they are now.
class MapFriend {
  const MapFriend({
    required this.id,
    required this.name,
    required this.color,
    required this.points,
    this.last,
  });

  final String id;
  final String name;
  final Color color;
  final List<TrackPoint> points;
  final LastPoint? last;
}

/// What the replay shows: print by print (`at(track, pos)`), or by the clock when [clock] is set (everyone where
/// they were at that moment; [own] = your trail frozen when ▶️ was pressed).
class ReplayView {
  const ReplayView({
    required this.track,
    required this.pos,
    this.clock,
    this.own = const [],
  });

  final List<TrackPoint> track;
  final double pos;
  final double? clock;
  final List<TrackPoint> own;

  (double, double)? get here {
    if (clock == null) {
      final p = at(track, pos);
      return (p.$1, p.$2);
    }
    return atTime(own, clock!);
  }
}

/// The map (port of the web's MapView.tsx): OSM tiles, paw prints, stops, friends, Hachiware.
class MapView extends ConsumerStatefulWidget {
  const MapView({
    required this.points,
    required this.stops,
    super.key,
    this.last,
    this.friends = const [],
    this.flyTo,
    this.replay,
    this.showTiles = true,
  });

  final List<TrackPoint> points;
  final List<Stop> stops;
  final LastPoint? last;
  final List<MapFriend> friends;

  /// (lon, lat) to fly to; a new value starts a new flight.
  final (double, double)? flyTo;
  final ReplayView? replay;

  /// Tests switch the network tiles off.
  final bool showTiles;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  final _map = MapController();
  bool _ready = false;
  bool _fitted = false;
  AnimationController? _flight;

  @override
  void initState() {
    super.initState();
    unawaited(_openWhereWeLeftOff());
  }

  Future<void> _openWhereWeLeftOff() async {
    final p = await ref.read(prefsProvider).startPoint();
    if (!mounted || p == null || _fitted || !_ready) return;
    _map.move(LatLng(p.$2, p.$1), 15);
  }

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (widget.flyTo != null && widget.flyTo != old.flyTo) {
      _fly(LatLng(widget.flyTo!.$2, widget.flyTo!.$1), 17);
    }
    _fitFirstData();
    if (widget.replay != null &&
        old.replay == null &&
        widget.replay!.track.length >= 2) {
      final first = widget.replay!.clock == null
          ? widget.replay!.track.first
          : widget.replay!.own.firstOrNull;
      if (first != null) {
        _map.move(LatLng(first.lat, first.lon), max(_map.camera.zoom, 16));
      }
    }
    _follow();
  }

  /// First data: open on the last point if known, else fit the prints.
  void _fitFirstData() {
    if (_fitted) return;
    final last = widget.last;
    if (last != null) {
      _fitted = true;
      _map.move(LatLng(last.lat, last.lon), 16);
      unawaited(ref.read(prefsProvider).rememberStart(last.lon, last.lat));
    } else if (widget.points.isNotEmpty) {
      _fitted = true;
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: [for (final p in widget.points) LatLng(p.lat, p.lon)],
          padding: const EdgeInsets.all(60),
          maxZoom: 16,
        ),
      );
    }
  }

  /// While replaying: the map follows when the walker nears the edge.
  void _follow() {
    final here = widget.replay?.here;
    if (here == null) return;
    final b = _map.camera.visibleBounds;
    final padLat = (b.north - b.south) * 0.2;
    final padLon = (b.east - b.west) * 0.2;
    final inside =
        here.$2 < b.north - padLat &&
        here.$2 > b.south + padLat &&
        here.$1 < b.east - padLon &&
        here.$1 > b.west + padLon;
    if (!inside) _map.move(LatLng(here.$2, here.$1), _map.camera.zoom);
  }

  void _fly(LatLng to, double zoom) {
    _flight?.dispose();
    final from = _map.camera.center;
    final z0 = _map.camera.zoom;
    final c = _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final curve = CurvedAnimation(parent: c, curve: Curves.easeInOut);
    c.addListener(() {
      final k = curve.value;
      _map.move(
        LatLng(
          from.latitude + (to.latitude - from.latitude) * k,
          from.longitude + (to.longitude - from.longitude) * k,
        ),
        z0 + (zoom - z0) * k,
      );
    });
    c.forward();
  }

  void _say(String text) => ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );

  void _onTap(TapPosition tap, LatLng _) {
    final camera = _map.camera;
    final p = nearestPrint(
      widget.points,
      tap.relative ?? Offset.zero,
      (q) => camera.latLngToScreenOffset(LatLng(q.lat, q.lon)),
    );
    if (p != null) {
      _say(
        '🐾 ${hhmmSec(p.t)}${p.acc != null ? ' · ±${p.acc!.round()} m' : ''}',
      );
    }
  }

  @override
  void dispose() {
    _flight?.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final replay = widget.replay;
    final here = replay?.here;
    final last = widget.last;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: home,
        onTap: _onTap,
        onMapReady: () {
          _ready = true;
          unawaited(_openWhereWeLeftOff());
          _fitFirstData();
        },
      ),
      children: [
        if (widget.showTiles)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(_pastel),
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.findme.mobile',
              maxZoom: 19,
              errorTileCallback: debugConsoleEnabled
                  ? (_, error, _) => DebugLog.instance.tileFailed(error)
                  : null,
            ),
          ),
        PawLayer(points: widget.points),
        for (final f in widget.friends)
          PawLayer(points: f.points, color: f.color),
        MarkerLayer(
          markers: [
            for (final s in widget.stops) _stopMarker(s),
            for (final f in widget.friends) ?_friendMarker(f, replay?.clock),
            if (replay == null && last != null)
              _hachiware(LatLng(last.lat, last.lon), 'Lần cuối thấy ở đây'),
            if (replay != null && here != null)
              _hachiware(LatLng(here.$2, here.$1), 'Phát lại'),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _stopMarker(Stop s) {
    final d = min(
      46,
      20 + sqrt(s.seconds / 60) * 2.2,
    ).roundToDouble(); // bigger for longer stays
    return Marker(
      point: LatLng(s.lat, s.lon),
      width: d,
      height: d,
      child: GestureDetector(
        onTap: () => _say(
          '${s.name ?? 'Một nơi xinh xinh'}\n${hhmmIso(s.start)} – ${hhmmIso(s.end)} · ${duration(s.seconds)}',
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Palette.pinkSoft,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Palette.shadow, blurRadius: 6)],
          ),
          alignment: Alignment.center,
          child: Text('🐾', style: TextStyle(fontSize: d * 0.5)),
        ),
      ),
    );
  }

  Marker? _friendMarker(MapFriend f, double? clock) {
    // Replaying together: where they were at that moment (not drawn before their first print); else where they are now.
    final here = clock != null
        ? atTime(f.points, clock)
        : (f.last == null ? null : (f.last!.lon, f.last!.lat));
    if (here == null) return null;
    final initial = f.name.trim().isEmpty
        ? '?'
        : f.name.trim().characters.first.toUpperCase();
    return Marker(
      point: LatLng(here.$2, here.$1),
      width: 34,
      height: 34,
      child: GestureDetector(
        onTap: () => _say(f.name),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: f.color, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: f.color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  /// Hachiware stands with her feet on the point (bottom centre).
  Marker _hachiware(LatLng at, String label) => Marker(
    point: at,
    width: 56,
    height: 66,
    alignment: Alignment.topCenter,
    child: Semantics(
      label: label,
      child: Image.asset('assets/images/hachiware.webp'),
    ),
  );
}

// Pastel tint like the web's `.osm-tiles` filter (approximation of saturate(0.6) sepia(0.15) brightness(1.05)).
const _pastel = <double>[
  0.78, 0.26, 0.04, 0, 6, //
  0.12, 0.88, 0.04, 0, 6, //
  0.10, 0.22, 0.70, 0, 6, //
  0, 0, 0, 1, 0, //
];
