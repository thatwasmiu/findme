/// Trip mode (travel-heatmap guide chapter 22): a trip-mode account records and is seen only during a trip, a timer
/// started here. Always-on accounts never see any of this.
enum TripPreset {
  m15('15m', '15 phút'),
  h1('1h', '1 giờ'),
  tonight('tonight', 'đến tối nay'),
  open('open', 'đến khi tắt');

  const TripPreset(this.key, this.label);

  /// What `PUT /me/sharing {start}` takes.
  final String key;
  final String label;
}

TripPreset? presetOf(String? key) {
  for (final p in TripPreset.values) {
    if (p.key == key) return p;
  }
  return null;
}

/// The account's mode and running trip as `GET /me` / `PUT /me/sharing` answer them. [until] null with [on] = "đến
/// khi tắt".
typedef Sharing = ({bool tripMode, bool on, DateTime? until});

/// null: the server has no trip mode yet (not deployed), so nothing changes.
Sharing? sharingFromJson(Map<String, dynamic> j) {
  final s = j['sharing'];
  if (s is! String) return null;
  final u = j['tripUntil'];
  return (
    tripMode: s == 'trip',
    on: j['trip'] == true,
    until: u is String ? DateTime.parse(u) : null,
  );
}

const _vn = Duration(hours: 7);

/// The end the server sets for [p] when started at [now] (used when the start could not reach it). "tonight" is
/// 23:59:59 in Vietnam, like the server.
DateTime? localEnd(TripPreset p, DateTime now) {
  final u = now.toUtc();
  switch (p) {
    case TripPreset.m15:
      return u.add(const Duration(minutes: 15));
    case TripPreset.h1:
      return u.add(const Duration(hours: 1));
    case TripPreset.tonight:
      final v = u.add(_vn);
      return DateTime.utc(v.year, v.month, v.day, 23, 59, 59).subtract(_vn);
    case TripPreset.open:
      return null;
  }
}

/// The trip's own end has passed (an open trip never ends by itself).
bool tripOver(DateTime? until, DateTime now) =>
    until != null && !now.isBefore(until);

/// "còn 42 phút", "còn 1 giờ 5 phút", "đến khi tắt". Minutes round up: 41 min 10 s left still says 42.
String tripLeft(DateTime? until, DateTime now) {
  if (until == null) return 'đến khi tắt';
  final s = until.difference(now).inSeconds;
  final m = s <= 0 ? 0 : (s + 59) ~/ 60;
  if (m < 60) return 'còn $m phút';
  final rest = m % 60;
  return rest == 0 ? 'còn ${m ~/ 60} giờ' : 'còn ${m ~/ 60} giờ $rest phút';
}
