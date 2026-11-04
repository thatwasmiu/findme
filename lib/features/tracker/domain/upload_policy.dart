/// Upload as soon as this many fixes wait…
const uploadAt = 50;

/// …or when this long has passed since the last successful upload (the default; the 🧭 sheet offers
/// [uploadChoices]).
const uploadEvery = Duration(minutes: 5);

const uploadChoices = [
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(hours: 1),
];

/// At most this many fixes per request.
const maxBatch = 500;

bool shouldUpload({
  required int queued,
  required DateTime? lastOk,
  required DateTime now,
  required DateTime? notBefore,
  Duration every = uploadEvery,
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
