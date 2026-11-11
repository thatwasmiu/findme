import 'dart:async';
import 'dart:math';

import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/features/bag/presentation/bag_widgets.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/pin_layer.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:findme/features/trail/presentation/hachiware.dart';
import 'package:findme/features/trail/presentation/paw_layer.dart';
import 'package:findme/features/trail/presentation/trail_painting.dart';
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
    this.avatar,
  });

  final String id;
  final String name;
  final Color color;
  final List<TrackPoint> points;
  final LastPoint? last;

  /// Look Back media id of their avatar.
  final String? avatar;
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
    this.pins = const [],
    this.onPin,
    this.center,
    this.myAvatar,
    this.onFriend,
  });

  /// Your avatar (Look Back media id): replaces Hachiware, live and in replay, once it has loaded.
  final String? myAvatar;

  /// Tapping a friend's marker (opens their bag) instead of showing their name.
  final void Function(MapFriend)? onFriend;

  final List<Pin> pins;
  final void Function(Pin)? onPin;

  /// Kept at the map's centre: a new pin goes there.
  final ValueNotifier<Spot>? center;

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
        // OSM has no tiles past 19: beyond it the map would be grey. Leaflet (the web) caps this by itself.
        maxZoom: 19,
        onTap: _onTap,
        // A move can come from didUpdateWidget, in the middle of a build: tell the listeners right after it.
        onPositionChanged: (camera, _) => scheduleMicrotask(() {
          if (mounted) {
            widget.center?.value = (
              lat: camera.center.latitude,
              lon: camera.center.longitude,
            );
          }
        }),
        onMapReady: () {
          _ready = true;
          unawaited(_openWhereWeLeftOff());
          _fitFirstData();
        },
      ),
      children: [
        if (widget.showTiles)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(pastelMatrix),
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
        MarkerLayer(markers: [for (final s in widget.stops) _stopMarker(s)]),
        PinBubbles(
          pins: widget.pins,
          onOpen: (p) => widget.onPin?.call(p),
          onZoomIn: _fly,
        ),
        MarkerLayer(
          markers: [
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
    // With a picture the marker is the web's 44 px avatar; until it loads (or without one), the 34 px initial.
    final size = f.avatar == null ? 34.0 : 44.0;
    return Marker(
      point: LatLng(here.$2, here.$1),
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: f.name,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () =>
              widget.onFriend != null ? widget.onFriend!(f) : _say(f.name),
          child: AvatarCircle(
            media: f.avatar,
            size: size,
            border: f.color,
            fallback: Initial(f.name, f.color),
          ),
        ),
      ),
    );
  }

  /// Hachiware stands with her feet on the point (bottom centre); your avatar, when you set one and it has
  /// loaded, is a circle centred on it.
  Marker _hachiware(LatLng at, String label) {
    final hachiware = Hachiware(label: label);
    final avatar = widget.myAvatar;
    if (avatar == null) {
      return Marker(
        point: at,
        width: 56,
        height: 66,
        alignment: Alignment.topCenter,
        child: hachiware,
      );
    }
    return Marker(
      point: at,
      width: 66,
      height: 66,
      child: Center(
        child: Semantics(
          label: label,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Palette.pink, spreadRadius: 3),
                BoxShadow(
                  color: Color(0x73EC4899),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: AvatarCircle(
              media: avatar,
              size: 56,
              border: Colors.white,
              borderWidth: 4,
              // until the picture loads: Hachiware's face
              fallback: Image.asset(
                'assets/images/hachiware.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
