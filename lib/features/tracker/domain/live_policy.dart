import 'dart:convert';
import 'dart:math';

import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/upload_policy.dart';
import 'package:findme/features/trail/domain/colors.dart';

/// Live positions over MQTT (travel-heatmap guide chapter 23). Send a fix only when it says something new: good
/// enough for `/ingest`, and at least max(5 m, acc / 2) from the last one sent, so a standstill's GPS jitter stays home.
bool worthPublishing(Fix f, Fix? lastSent) =>
    f.acc <= maxAccuracyM &&
    (lastSent == null ||
        distanceM(
              (lat: lastSent.lat, lon: lastSent.lon),
              (lat: f.lat, lon: f.lon),
            ) >=
            max(minMoveM, f.acc / 2));

double _round(double v, int places) {
  final m = pow(10, places);
  return (v * m).round() / m;
}

/// The broker takes exactly `{lat, lon, ts, acc}`: 6 decimals, `ts` in whole epoch seconds, at most 256 bytes.
String livePayload(Fix f) => jsonEncode({
  'lat': _round(f.lat, 6),
  'lon': _round(f.lon, 6),
  'ts': f.at.millisecondsSinceEpoch ~/ 1000,
  'acc': _round(f.acc, 1),
});

String liveTopic(String accountId) => 'live/$accountId';
