import 'dart:io';
import 'dart:typed_data';

import 'package:findme/features/widget/domain/tile_math.dart';
import 'package:findme/features/widget/domain/widget_tiles.dart';

typedef TileFetch = Future<Uint8List?> Function(TileKey key);

const _freshFor = Duration(days: 7);
const _retryAfter = Duration(minutes: 5);

/// Map tiles on the phone. OpenStreetMap's tile usage policy asks for at least a week's caching.
class TileCache implements WidgetTiles {
  TileCache(this._dir, this._fetch, this._now, {this.maxFiles = 200});

  final Directory _dir;
  final TileFetch _fetch;
  final DateTime Function() _now;
  final int maxFiles;

  /// A tile that just failed is left alone for a while. In memory only: a restart may try again.
  final _failedAt = <TileKey, DateTime>{};

  File _file(TileKey k) => File('${_dir.path}/${k.z}_${k.x}_${k.y}.png');

  @override
  Future<Uint8List?> get(TileKey key) async {
    final file = _file(key);
    final exists = file.existsSync();
    if (exists && _now().difference(file.lastModifiedSync()) < _freshFor) {
      return file.readAsBytes();
    }
    final failed = _failedAt[key];
    if (failed == null || _now().difference(failed) >= _retryAfter) {
      final bytes = await _fetch(key);
      if (bytes != null) {
        _failedAt.remove(key);
        await _store(file, bytes);
        return bytes;
      }
      _failedAt[key] = _now();
    }
    return exists ? file.readAsBytes() : null; // an old map beats a blank square
  }

  Future<void> _store(File file, Uint8List bytes) async {
    await _dir.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
    await file.setLastModified(_now());
    _prune();
  }

  /// ponytail: oldest-first by file time, at most [maxFiles] (about 4 MB); enough for a daily area, not a long trip.
  void _prune() {
    final files =
        _dir.listSync().whereType<File>().where(
            (f) => f.path.endsWith('.png'),
          ).toList()
          ..sort(
            (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
          );
    if (files.length <= maxFiles) return;
    for (final f in files.take(files.length - maxFiles)) {
      f.deleteSync();
    }
  }
}

/// The real fetch. Null on any failure.
Future<Uint8List?> fetchOsmTile(TileKey key) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..userAgent = 'flutter_map (app.findme.mobile)';
  try {
    final request = await client.getUrl(
      Uri.https(
        'tile.openstreetmap.org',
        '/${key.z}/${key.x}/${key.y}.png',
      ),
    );
    final response = await request.close().timeout(
      const Duration(seconds: 20),
    );
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final chunks = BytesBuilder(copy: false);
    await response.forEach(chunks.add);
    return chunks.takeBytes();
  } on Object {
    return null;
  } finally {
    client.close();
  }
}
