import 'package:flutter/foundation.dart';

/// A time window as the /track API takes it: ISO strings in JS `toISOString()` form.
@immutable
class DateRange {
  const DateRange({required this.from, required this.to});

  final String from;
  final String to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'DateRange($from → $to)';
}

// "Tất cả" is gone on the web too: the trail API serves at most ~31 days at a time.
enum Preset {
  today('Hôm nay'),
  yesterday('Hôm qua'),
  d7('7 ngày'),
  d30('30 ngày');

  Preset(this.label);
  final String label;
}

/// JS `toISOString()`: UTC, always milliseconds, `Z` (Dart would print microseconds or drop them).
String isoMs(DateTime d) {
  final u = d.toUtc();
  final ms = DateTime.utc(
    u.year,
    u.month,
    u.day,
    u.hour,
    u.minute,
    u.second,
    u.millisecond,
  );
  final s = ms.toIso8601String(); // "…T03:04:05.006Z"
  return s.contains('.') ? s : s.replaceFirst('Z', '.000Z');
}

DateTime _localMidnight(DateTime now, int back) {
  final l = now.toLocal();
  return DateTime(l.year, l.month, l.day - back);
}

DateRange presetRange(Preset p, DateTime now) {
  final to = isoMs(now);
  switch (p) {
    case Preset.yesterday:
      return DateRange(
        from: isoMs(_localMidnight(now, 1)),
        to: isoMs(
          _localMidnight(now, 0).subtract(const Duration(milliseconds: 1)),
        ),
      );
    case Preset.today:
      return DateRange(from: isoMs(_localMidnight(now, 0)), to: to);
    case Preset.d7:
      return DateRange(from: isoMs(_localMidnight(now, 6)), to: to);
    case Preset.d30:
      return DateRange(from: isoMs(_localMidnight(now, 29)), to: to);
  }
}

/// Local "YYYY-MM-DD" dates; `to` is the last millisecond of toYmd's local day.
DateRange customRange(String fromYmd, String toYmd) {
  final f = fromYmd.split('-').map(int.parse).toList();
  final t = toYmd.split('-').map(int.parse).toList();
  return DateRange(
    from: isoMs(DateTime(f[0], f[1], f[2])),
    to: isoMs(
      DateTime(t[0], t[1], t[2] + 1).subtract(const Duration(milliseconds: 1)),
    ),
  );
}

/// True when the range is within one local calendar day.
bool isOneDay(DateRange r) {
  final a = DateTime.parse(r.from).toLocal();
  final b = DateTime.parse(r.to).toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// True when the range reaches into today (local), so new points can still arrive in it.
bool isLive(DateRange r, {DateTime? now}) =>
    !DateTime.parse(r.to).isBefore(_localMidnight(now ?? DateTime.now(), 0));

/// The end to ask the server for: "now" while the range reaches today, else its own end.
String liveTo(DateRange r, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final s = isoMs(n);
  if (r.to.compareTo(s) > 0) return r.to;
  return isLive(r, now: n) ? s : r.to;
}
