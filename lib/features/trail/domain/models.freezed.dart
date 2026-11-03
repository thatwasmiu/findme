// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Stop {

 double get lon; double get lat; String get start; String get end; int get seconds; String? get name;
/// Create a copy of Stop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StopCopyWith<Stop> get copyWith => _$StopCopyWithImpl<Stop>(this as Stop, _$identity);

  /// Serializes this Stop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Stop;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Stop&&(identical(other.lon, _this.lon) || other.lon == _this.lon)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.seconds, _this.seconds) || other.seconds == _this.seconds)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Stop;
  return Object.hash(runtimeType,_this.lon,_this.lat,_this.start,_this.end,_this.seconds,_this.name);
}

@override
String toString() {
  final _this = this as Stop;
  return 'Stop(lon: ${_this.lon}, lat: ${_this.lat}, start: ${_this.start}, end: ${_this.end}, seconds: ${_this.seconds}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $StopCopyWith<$Res>  {
  factory $StopCopyWith(Stop value, $Res Function(Stop) _then) = _$StopCopyWithImpl;
@useResult
$Res call({
 double lon, double lat, String start, String end, int seconds, String? name
});




}
/// @nodoc
class _$StopCopyWithImpl<$Res>
    implements $StopCopyWith<$Res> {
  _$StopCopyWithImpl(this._self, this._then);

  final Stop _self;
  final $Res Function(Stop) _then;

/// Create a copy of Stop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lon = null,Object? lat = null,Object? start = null,Object? end = null,Object? seconds = null,Object? name = freezed,}) {
  return _then(Stop(
lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Stop].
extension StopPatterns on Stop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Stop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Stop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Stop value)  $default,){
final _that = this;
switch (_that) {
case _Stop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Stop value)?  $default,){
final _that = this;
switch (_that) {
case _Stop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lon,  double lat,  String start,  String end,  int seconds,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Stop() when $default != null:
return $default(_that.lon,_that.lat,_that.start,_that.end,_that.seconds,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lon,  double lat,  String start,  String end,  int seconds,  String? name)  $default,) {final _that = this;
switch (_that) {
case _Stop():
return $default(_that.lon,_that.lat,_that.start,_that.end,_that.seconds,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lon,  double lat,  String start,  String end,  int seconds,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _Stop() when $default != null:
return $default(_that.lon,_that.lat,_that.start,_that.end,_that.seconds,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Stop extends Stop {
  const _Stop({required this.lon, required this.lat, required this.start, required this.end, required this.seconds, this.name}): super._();
  factory _Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);

@override final  double lon;
@override final  double lat;
@override final  String start;
@override final  String end;
@override final  int seconds;
@override final  String? name;

/// Create a copy of Stop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StopCopyWith<_Stop> get copyWith => __$StopCopyWithImpl<_Stop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StopToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Stop&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lon,lat,start,end,seconds,name);
}

@override
String toString() {
    return 'Stop(lon: $lon, lat: $lat, start: $start, end: $end, seconds: $seconds, name: $name)';
}


}

/// @nodoc
abstract mixin class _$StopCopyWith<$Res> implements $StopCopyWith<$Res> {
  factory _$StopCopyWith(_Stop value, $Res Function(_Stop) _then) = __$StopCopyWithImpl;
@override @useResult
$Res call({
 double lon, double lat, String start, String end, int seconds, String? name
});




}
/// @nodoc
class __$StopCopyWithImpl<$Res>
    implements _$StopCopyWith<$Res> {
  __$StopCopyWithImpl(this._self, this._then);

  final _Stop _self;
  final $Res Function(_Stop) _then;

/// Create a copy of Stop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lon = null,Object? lat = null,Object? start = null,Object? end = null,Object? seconds = null,Object? name = freezed,}) {
  return _then(_Stop(
lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LastPoint {

 double get lon; double get lat; String get ts;
/// Create a copy of LastPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastPointCopyWith<LastPoint> get copyWith => _$LastPointCopyWithImpl<LastPoint>(this as LastPoint, _$identity);

  /// Serializes this LastPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LastPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastPoint&&(identical(other.lon, _this.lon) || other.lon == _this.lon)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.ts, _this.ts) || other.ts == _this.ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LastPoint;
  return Object.hash(runtimeType,_this.lon,_this.lat,_this.ts);
}

@override
String toString() {
  final _this = this as LastPoint;
  return 'LastPoint(lon: ${_this.lon}, lat: ${_this.lat}, ts: ${_this.ts})';
}


}

/// @nodoc
abstract mixin class $LastPointCopyWith<$Res>  {
  factory $LastPointCopyWith(LastPoint value, $Res Function(LastPoint) _then) = _$LastPointCopyWithImpl;
@useResult
$Res call({
 double lon, double lat, String ts
});




}
/// @nodoc
class _$LastPointCopyWithImpl<$Res>
    implements $LastPointCopyWith<$Res> {
  _$LastPointCopyWithImpl(this._self, this._then);

  final LastPoint _self;
  final $Res Function(LastPoint) _then;

/// Create a copy of LastPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lon = null,Object? lat = null,Object? ts = null,}) {
  return _then(LastPoint(
lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LastPoint].
extension LastPointPatterns on LastPoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastPoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastPoint value)  $default,){
final _that = this;
switch (_that) {
case _LastPoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastPoint value)?  $default,){
final _that = this;
switch (_that) {
case _LastPoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lon,  double lat,  String ts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastPoint() when $default != null:
return $default(_that.lon,_that.lat,_that.ts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lon,  double lat,  String ts)  $default,) {final _that = this;
switch (_that) {
case _LastPoint():
return $default(_that.lon,_that.lat,_that.ts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lon,  double lat,  String ts)?  $default,) {final _that = this;
switch (_that) {
case _LastPoint() when $default != null:
return $default(_that.lon,_that.lat,_that.ts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastPoint implements LastPoint {
  const _LastPoint({required this.lon, required this.lat, required this.ts});
  factory _LastPoint.fromJson(Map<String, dynamic> json) => _$LastPointFromJson(json);

@override final  double lon;
@override final  double lat;
@override final  String ts;

/// Create a copy of LastPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastPointCopyWith<_LastPoint> get copyWith => __$LastPointCopyWithImpl<_LastPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastPoint&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.ts, ts) || other.ts == ts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lon,lat,ts);
}

@override
String toString() {
    return 'LastPoint(lon: $lon, lat: $lat, ts: $ts)';
}


}

/// @nodoc
abstract mixin class _$LastPointCopyWith<$Res> implements $LastPointCopyWith<$Res> {
  factory _$LastPointCopyWith(_LastPoint value, $Res Function(_LastPoint) _then) = __$LastPointCopyWithImpl;
@override @useResult
$Res call({
 double lon, double lat, String ts
});




}
/// @nodoc
class __$LastPointCopyWithImpl<$Res>
    implements _$LastPointCopyWith<$Res> {
  __$LastPointCopyWithImpl(this._self, this._then);

  final _LastPoint _self;
  final $Res Function(_LastPoint) _then;

/// Create a copy of LastPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lon = null,Object? lat = null,Object? ts = null,}) {
  return _then(_LastPoint(
lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Track {

 List<TrackPoint> get points; List<Stop> get stops; LastPoint? get last;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Track;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&const DeepCollectionEquality().equals(other.points, _this.points)&&const DeepCollectionEquality().equals(other.stops, _this.stops)&&(identical(other.last, _this.last) || other.last == _this.last));
}


@override
int get hashCode {
  final _this = this as Track;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.points),const DeepCollectionEquality().hash(_this.stops),_this.last);
}

@override
String toString() {
  final _this = this as Track;
  return 'Track(points: ${_this.points}, stops: ${_this.stops}, last: ${_this.last})';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 List<TrackPoint> points, List<Stop> stops, LastPoint? last
});


$LastPointCopyWith<$Res>? get last;

}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,Object? stops = null,Object? last = freezed,}) {
  return _then(Track(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<TrackPoint>,stops: null == stops ? _self.stops : stops // ignore: cast_nullable_to_non_nullable
as List<Stop>,last: freezed == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as LastPoint?,
  ));
}
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastPointCopyWith<$Res>? get last {
    if (_self.last == null) {
    return null;
  }

  return $LastPointCopyWith<$Res>(_self.last!, (value) {
    return _then(_self.copyWith(last: value));
  });
}
}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TrackPoint> points,  List<Stop> stops,  LastPoint? last)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.points,_that.stops,_that.last);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TrackPoint> points,  List<Stop> stops,  LastPoint? last)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.points,_that.stops,_that.last);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TrackPoint> points,  List<Stop> stops,  LastPoint? last)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.points,_that.stops,_that.last);case _:
  return null;

}
}

}

/// @nodoc


class _Track implements Track {
  const _Track({ List<TrackPoint> points = const <TrackPoint>[],  List<Stop> stops = const <Stop>[], this.last}): _points = points,_stops = stops;
  

 final  List<TrackPoint> _points;
@override@JsonKey() List<TrackPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  List<Stop> _stops;
@override@JsonKey() List<Stop> get stops {
  if (_stops is EqualUnmodifiableListView) return _stops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stops);
}

@override final  LastPoint? last;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&const DeepCollectionEquality().equals(other.points, _points)&&const DeepCollectionEquality().equals(other.stops, _stops)&&(identical(other.last, last) || other.last == last));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_points),const DeepCollectionEquality().hash(_stops),last);
}

@override
String toString() {
    return 'Track(points: $points, stops: $stops, last: $last)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 List<TrackPoint> points, List<Stop> stops, LastPoint? last
});


@override $LastPointCopyWith<$Res>? get last;

}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,Object? stops = null,Object? last = freezed,}) {
  return _then(_Track(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<TrackPoint>,stops: null == stops ? _self._stops : stops // ignore: cast_nullable_to_non_nullable
as List<Stop>,last: freezed == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as LastPoint?,
  ));
}

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastPointCopyWith<$Res>? get last {
    if (_self.last == null) {
    return null;
  }

  return $LastPointCopyWith<$Res>(_self.last!, (value) {
    return _then(_self.copyWith(last: value));
  });
}
}

// dart format on
