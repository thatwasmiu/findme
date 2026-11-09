import 'dart:typed_data';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/widget/domain/day_log.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/widget_tiles.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the tracker tells the home-screen widget.
abstract interface class TrailWidget {
  void onFix(Fix f);
  void start();
  void stop();
  Future<void> refresh();
  Future<void> clear();
}

/// Tests and iPhone: no widget.
class NoTrailWidget implements TrailWidget {
  @override
  void onFix(Fix f) {}
  @override
  void start() {}
  @override
  void stop() {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> clear() async {}
}

final trailWidgetProvider = Provider<TrailWidget>((_) => NoTrailWidget());

/// What one picture shows.
@immutable
class WidgetScene {
  const WidgetScene({required this.trail, required this.here});

  final List<TrackPoint> trail;
  final TrackPoint here;
}

/// The phone's home screen.
abstract interface class WidgetHost {
  Future<void> publish(Uint8List png, DateTime lastFix);
  Future<void> refreshLabel();
  Future<void> clear();
}

typedef WidgetRender =
    Future<Uint8List> Function(
      WidgetScene scene,
      Map<TileKey, Uint8List> tiles,
    );

@immutable
class WidgetParts {
  const WidgetParts({
    required this.days,
    required this.tiles,
    required this.host,
    required this.render,
  });

  final DayLog days;
  final WidgetTiles tiles;
  final WidgetHost host;
  final WidgetRender render;
}
