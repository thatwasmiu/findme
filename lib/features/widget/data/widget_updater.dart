import 'dart:async';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/widget/domain/day_log.dart';
import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/foundation.dart';

/// Keeps the home-screen widget current. Only the one-minute timer draws (plus [start] and [refresh]), which is what
/// holds redraws to one a minute and still draws the last fix of a burst. Never throws: the widget must not be able
/// to disturb the tracker.
class WidgetUpdater implements TrailWidget {
  WidgetUpdater(Future<WidgetParts> Function() load, this._now) : _load = load;

  final Future<WidgetParts> Function() _load;
  final DateTime Function() _now;

  late final Future<WidgetParts> _parts = _load();

  Timer? _timer;
  bool _dirty = false;
  bool _closed = false;
  bool _drawing = false;
  DateTime? _drawnAt;

  /// Bumped by [clear]: a draw or a write begun before it must not bring the location back.
  int _generation = 0;
  Future<void> _writes = Future.value();
  Future<void> _publishing = Future.value();

  @override
  void onFix(Fix f) {
    if (_closed) return;
    _dirty = true;
    final generation = _generation;
    _writes = _writes.then((_) async {
      if (generation != _generation) return;
      try {
        await (await _parts).days.append(f);
      } on Object catch (e) {
        _log(e);
      }
    });
  }

  @override
  void start() {
    _closed = false;
    if (_timer != null) return;
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_tick()),
    );
    unawaited(_draw());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> refresh() => _draw();

  @override
  Future<void> clear() async {
    _closed = true;
    _generation++;
    stop();
    await _writes;
    await _publishing;
    // Separately: a stuck file must not leave the location on the home screen, nor the reverse.
    await _quietly((parts) => parts.host.clear());
    await _quietly((parts) => parts.days.clear());
  }

  Future<void> _quietly(Future<void> Function(WidgetParts) op) async {
    try {
      await op(await _parts);
    } on Object catch (e) {
      _log(e);
    }
  }

  Future<void> _tick() async {
    final drawnAt = _drawnAt;
    final newDay = drawnAt != null && !sameLocalDay(drawnAt, _now());
    if (_dirty || newDay) {
      await _draw();
      return;
    }
    await _quietly((parts) => parts.host.refreshLabel());
  }

  Future<void> _draw() async {
    if (_drawing) return;
    _drawing = true;
    _dirty = false; // a fix arriving during the draw sets it again
    final generation = _generation;
    try {
      await _writes;
      final parts = await _parts;
      final trail = await parts.days.read(_now());
      final last = trail.last;
      if (last == null || generation != _generation) return;
      final tiles = <TileKey, Uint8List>{};
      for (final key in tilesFor(last.lat, last.lon)) {
        final bytes = await parts.tiles.get(key);
        if (bytes != null) tiles[key] = bytes;
      }
      final png = await parts.render(
        WidgetScene(
          trail: trail.today.map(_point).toList(),
          here: _point(last),
        ),
        tiles,
      );
      if (generation != _generation) return;
      final publish = parts.host.publish(png, last.at);
      _publishing = publish.then<void>((_) {}, onError: (_) {}); // never fails
      await publish;
      _drawnAt = _now();
    } on Object catch (e) {
      _dirty = true; // the next minute tries again
      _log(e);
    } finally {
      _drawing = false;
    }
  }

  static TrackPoint _point(Fix f) =>
      TrackPoint(f.lon, f.lat, f.at.millisecondsSinceEpoch ~/ 1000, f.acc);

  static void _log(Object e) => debugPrint('widget: ${e.runtimeType}');
}
