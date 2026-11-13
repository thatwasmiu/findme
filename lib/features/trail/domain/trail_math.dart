import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';

/// Where someone was at clock time [t] (epoch seconds): null before their first print, a straight line between two
/// prints, standing still at the last print after it. Used to replay several people together.
(double, double)? atTime(List<TrackPoint> pts, num t) {
  if (pts.isEmpty || t < pts.first.t) return null;
  var i = 0;
  // ponytail: linear scan per frame; binary search if days get huge
  while (i < pts.length - 1 && pts[i + 1].t <= t) {
    i++;
  }
  final a = pts[i];
  if (i == pts.length - 1) return (a.lon, a.lat);
  final b = pts[i + 1];
  final span = b.t - a.t;
  final k = (t - a.t) / (span == 0 ? 1 : span);
  return (a.lon + (b.lon - a.lon) * k, a.lat + (b.lat - a.lat) * k);
}

/// Span to replay several people together: earliest to latest print of anyone. null = no friend has prints.
(int, int)? togetherSpan(List<TrackPoint> own, List<List<TrackPoint>> others) {
  final tracks = [own, ...others].where((p) => p.isNotEmpty).toList();
  if (own.isEmpty || tracks.length < 2) return null;
  final t0 = tracks.map((p) => p.first.t).reduce((a, b) => a < b ? a : b);
  final t1 = tracks.map((p) => p.last.t).reduce((a, b) => a > b ? a : b);
  return t1 > t0 ? (t0, t1) : null;
}

/// Where the replay is at [pos] (a fractional index into [pts]): (lon, lat, epoch seconds).
(double, double, double) at(List<TrackPoint> pts, double pos) {
  final f = pos.clamp(0, pts.length - 1).toDouble();
  final i = f.floor();
  final k = f - i;
  final a = pts[i];
  final b = pts[i + 1 < pts.length ? i + 1 : pts.length - 1];
  return (
    a.lon + (b.lon - a.lon) * k,
    a.lat + (b.lat - a.lat) * k,
    a.t + (b.t - a.t) * k,
  );
}

sealed class TimelineEntry {
  const TimelineEntry();
}

class StopEntry extends TimelineEntry {
  const StopEntry(this.stop);
  final Stop stop;
}

class MoveEntry extends TimelineEntry {
  const MoveEntry({
    required this.start,
    required this.end,
    required this.km,
    required this.to,
  });
  final int start;
  final int end;
  final double km;

  /// (lon, lat) of the last print of the move.
  final (double, double) to;
}

int _sec(String iso) => DateTime.parse(iso).millisecondsSinceEpoch ~/ 1000;

/// A day as stays and the moves between them (moves: the points strictly between two stays).
List<TimelineEntry> timeline(List<TrackPoint> points, List<Stop> stops) {
  final out = <TimelineEntry>[];
  num cursor = double.negativeInfinity;
  final sorted = [...stops]..sort((a, b) => a.start.compareTo(b.start));
  void pushMove(num until) {
    final seg = points.where((p) => p.t > cursor && p.t < until).toList();
    if (seg.length < 2) return;
    var m = 0.0;
    for (var i = 1; i < seg.length; i++) {
      m += distanceM(
        (lat: seg[i - 1].lat, lon: seg[i - 1].lon),
        (lat: seg[i].lat, lon: seg[i].lon),
      );
    }
    if (m < 100) return; // GPS wobble, not a trip
    final last = seg.last;
    out.add(
      MoveEntry(
        start: seg.first.t,
        end: last.t,
        km: m / 1000,
        to: (last.lon, last.lat),
      ),
    );
  }

  for (final s in sorted) {
    pushMove(_sec(s.start));
    out.add(StopEntry(s));
    cursor = _sec(s.end);
  }
  pushMove(double.infinity);
  return out;
}

/// Many days: one row per name with the total time (at its longest stay).
List<Stop> topStops(List<Stop> stops, {int n = 10}) {
  final byName = <String, Stop>{};
  for (final s in [...stops]..sort((a, b) => b.seconds.compareTo(a.seconds))) {
    final key =
        s.name ?? '${s.lat.toStringAsFixed(3)},${s.lon.toStringAsFixed(3)}';
    final seen = byName[key];
    byName[key] = seen == null
        ? s
        : seen.copyWith(seconds: seen.seconds + s.seconds);
  }
  return (byName.values.toList()
        ..sort((a, b) => b.seconds.compareTo(a.seconds)))
      .take(n)
      .toList();
}

const int _marginS = 15 * 60; // the server smooths and thins inside the window: redo a little before the end

/// Where a background refresh should start: from the start of the last stop while you are still there, else 15 min
/// before your last print. Never before [rangeFrom]; nothing loaded yet → the whole range.
String tailFrom(Track prev, String rangeFrom) {
  if (prev.points.isEmpty) return rangeFrom;
  final last = prev.points.last;
  final stop = prev.stops.isEmpty ? null : prev.stops.last;
  final fromMs = stop != null && _sec(stop.end) >= last.t - _marginS
      ? DateTime.parse(stop.start).millisecondsSinceEpoch
      : (last.t - _marginS) * 1000;
  return fromMs > DateTime.parse(rangeFrom).millisecondsSinceEpoch
      ? isoMs(DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true))
      : rangeFrom;
}

/// The trail already loaded before [from], then the freshly fetched window from [from] on.
Track mergeTail(Track prev, Track tail, String from) {
  final t = DateTime.parse(from).millisecondsSinceEpoch;
  return Track(
    points: [...prev.points.where((p) => p.t * 1000 < t), ...tail.points],
    stops: [
      ...prev.stops.where(
        (s) => DateTime.parse(s.end).millisecondsSinceEpoch < t,
      ),
      ...tail.stops,
    ],
    last: tail.last ?? prev.last,
  );
}

/// What to ask /track for one shown friend: `<id>~<since>~<have>`. Nothing yet, or only yesterday's: the whole day
/// (empty since). Else only the newest part (like your own trail) and the newest time we hold, so an unchanged friend
/// costs the server one tiny read.
String friendAsk(String id, FriendTrail? d, String todayIso) {
  if (d == null ||
      d.points.isEmpty ||
      d.points.first.t * 1000 <
          DateTime.parse(todayIso).millisecondsSinceEpoch) {
    return '$id~~';
  }
  return '$id~${tailFrom(Track(points: d.points), todayIso)}~${d.last?.ts ?? ''}';
}

/// Fold a friend's answer into what we hold (the web's `friendMerge`). Prints from before today ([todayStart], epoch
/// ms) are dropped: friends only share today; so are prints from before their trip started (`visibleFrom`).
/// `trip: false`: their trip ended, nothing at all.
FriendTrail friendMerge(FriendTrail? prev, FriendPart got, int todayStart) {
  if (got.unchanged && prev != null) return prev;
  if (got.trip == false) return (points: const [], last: null);
  final vf = got.visibleFrom == null
      ? 0
      : DateTime.parse(got.visibleFrom!).millisecondsSinceEpoch;
  final floor = vf > todayStart ? vf : todayStart;
  final last = prev?.last;
  final base = Track(
    points: [...?prev?.points.where((p) => p.t * 1000 >= floor)],
    last:
        last != null && DateTime.parse(last.ts).millisecondsSinceEpoch >= floor
        ? last
        : null,
  );
  final m = mergeTail(
    base,
    Track(points: got.points, last: got.last),
    got.from ??
        isoMs(DateTime.fromMillisecondsSinceEpoch(todayStart, isUtc: true)),
  );
  return (points: m.points, last: m.last);
}
