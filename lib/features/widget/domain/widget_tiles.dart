import 'dart:typed_data';

import 'package:findme/features/widget/domain/tile_math.dart';

/// A tile's PNG, or null when it is neither on the phone nor reachable.
abstract interface class WidgetTiles {
  Future<Uint8List?> get(TileKey key);
}
