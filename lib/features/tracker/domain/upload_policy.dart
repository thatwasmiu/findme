/// Upload as soon as this many fixes wait…
const uploadAt = 50;

/// …or when this long has passed since the last successful upload: a minute while moving (a friend who opens the
/// map mid-trip, with no live tail yet, sees a trail at most a minute behind), five while still. Live movement goes
/// over MQTT, so `/ingest` can wait.
const movingEvery = Duration(minutes: 1);
const stillEvery = Duration(minutes: 5);

/// The server's `MAX_ACCURACY_M` (rougher fixes are not stored) and `MIN_MOVE_M` (closer ones count as standing
/// still).
const maxAccuracyM = 100.0;
const minMoveM = 5.0;

/// [lastMove]: when a fix last moved [minMoveM] from the one before it.
Duration uploadWait({required DateTime? lastMove, required DateTime now}) =>
    lastMove != null && now.difference(lastMove) < movingEvery
    ? movingEvery
    : stillEvery;

/// At most this many fixes per request.
const maxBatch = 500;

bool shouldUpload({
  required int queued,
  required DateTime? lastOk,
  required DateTime now,
  required DateTime? notBefore,
  Duration every = movingEvery,
}) {
  if (queued == 0) return false;
  if (notBefore != null && now.isBefore(notBefore)) return false;
  return queued >= uploadAt ||
      lastOk == null ||
      now.difference(lastOk) >= every;
}

/// Wait after the [failures]-th failure in a row: 1, 2, 4, 8, 16, then 30 minutes.
Duration backoff(int failures) {
  final m = 1 << (failures - 1).clamp(0, 5);
  return Duration(minutes: m > 30 ? 30 : m);
}
