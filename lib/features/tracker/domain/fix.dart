import 'package:flutter/foundation.dart';

/// One GPS position recorded by this phone, waiting in the queue until the server has stored it.
@immutable
class Fix {
  const Fix({
    required this.at,
    required this.lat,
    required this.lon,
    required this.acc,
  });

  factory Fix.fromJson(Map<String, dynamic> j) => Fix(
    at: DateTime.parse(j['t'] as String),
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    acc: (j['acc'] as num).toDouble(),
  );

  final DateTime at;
  final double lat;
  final double lon;

  /// Horizontal accuracy in metres.
  final double acc;

  /// One queue line.
  Map<String, dynamic> toJson() => {
    't': at.toUtc().toIso8601String(),
    'lat': lat,
    'lon': lon,
    'acc': acc,
  };

  @override
  bool operator ==(Object other) =>
      other is Fix &&
      other.at.isAtSameMomentAs(at) &&
      other.lat == lat &&
      other.lon == lon &&
      other.acc == acc;

  @override
  int get hashCode => Object.hash(at.millisecondsSinceEpoch, lat, lon, acc);
}

/// The body Overland sends, which `/ingest` reads (travel-heatmap `lambdas/src/overland.ts`).
Map<String, dynamic> overlandBatch(List<Fix> fixes, String deviceId) => {
  'locations': [
    for (final f in fixes)
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [f.lon, f.lat],
        },
        'properties': {
          'timestamp': f.at.toUtc().toIso8601String(),
          'horizontal_accuracy': f.acc,
          'device_id': deviceId,
        },
      },
  ],
};

/// `iphone` is the id Overland used, so an iPhone's points keep the same key on the server.
String get deviceIdForPlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'iphone' : 'android';
