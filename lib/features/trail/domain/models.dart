import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// One paw print: the /track wire format `[lon, lat, epoch seconds, accuracy metres | null]`.
@immutable
class TrackPoint {
  const TrackPoint(this.lon, this.lat, this.t, [this.acc]);

  factory TrackPoint.fromJson(List<dynamic> j) => TrackPoint(
    (j[0] as num).toDouble(),
    (j[1] as num).toDouble(),
    (j[2] as num).toInt(),
    (j.length > 3 ? j[3] as num? : null)?.toDouble(),
  );

  final double lon;
  final double lat;

  /// Epoch seconds.
  final int t;
  final double? acc;

  @override
  bool operator ==(Object other) =>
      other is TrackPoint &&
      other.lon == lon &&
      other.lat == lat &&
      other.t == t &&
      other.acc == acc;

  @override
  int get hashCode => Object.hash(lon, lat, t, acc);

  @override
  String toString() => 'TrackPoint($lon, $lat, $t, $acc)';

  List<Object?> toJson() => [lon, lat, t, acc];
}

List<TrackPoint> trackPointsFromJson(Object? j) => [
  for (final p in (j as List<dynamic>? ?? const []))
    TrackPoint.fromJson(p as List<dynamic>),
];

@freezed
abstract class Stop with _$Stop {
  const factory Stop({
    required double lon,
    required double lat,
    required String start,
    required String end,
    required int seconds,
    String? name,
  }) = _Stop;
  const Stop._();

  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);

  DateTime get startAt => DateTime.parse(start);
  DateTime get endAt => DateTime.parse(end);
}

/// The most recent stored point overall (not limited to the date range).
@freezed
abstract class LastPoint with _$LastPoint {
  const factory LastPoint({
    required double lon,
    required double lat,
    required String ts,
  }) = _LastPoint;

  factory LastPoint.fromJson(Map<String, dynamic> json) =>
      _$LastPointFromJson(json);
}

@freezed
abstract class Track with _$Track {
  const factory Track({
    @Default(<TrackPoint>[]) List<TrackPoint> points,
    @Default(<Stop>[]) List<Stop> stops,
    LastPoint? last,
  }) = _Track;

  static const empty = Track();
}

/// One shown friend as the app holds it: today's prints and their newest point.
typedef FriendTrail = ({List<TrackPoint> points, LastPoint? last});

/// A friend's part of the combined /track answer.
@immutable
class FriendPart {
  const FriendPart({
    required this.id,
    this.unchanged = false,
    this.from,
    this.points = const [],
    this.last,
    this.trip,
    this.visibleFrom,
  });

  factory FriendPart.fromJson(Map<String, dynamic> j) => FriendPart(
    id: j['id'] as String,
    unchanged: j['unchanged'] == true,
    from: j['from'] as String?,
    trip: j['trip'] as bool?,
    visibleFrom: j['visibleFrom'] as String?,
    points: trackPointsFromJson(j['points']),
    last: j['last'] == null
        ? null
        : LastPoint.fromJson(j['last'] as Map<String, dynamic>),
  );

  final String id;
  final bool unchanged;
  final String? from;
  final List<TrackPoint> points;
  final LastPoint? last;

  /// false: a trip-mode friend not on a trip; nothing of them may be shown (travel-heatmap chapter 22).
  final bool? trip;

  /// Nothing before this may be shown (their trip started later than midnight).
  final String? visibleFrom;
}

/// What `GET /track` answers: your trail (or [unchanged]: nothing new since `have`, only [Track.last] is filled) and
/// the shown friends' parts.
@immutable
class TrackAnswer {
  const TrackAnswer(
    this.track, {
    this.unchanged = false,
    this.friends = const [],
  });

  final Track track;
  final bool unchanged;
  final List<FriendPart> friends;
}
