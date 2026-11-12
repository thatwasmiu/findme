// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Share {

 String get id; String get label; String get createdAt; String get expiresAt; bool get route;/// First local day of the shared route ("YYYY-MM-DD"); null = today only.
 String? get routeFrom;/// Anyone holding the link can open the bag.
 bool get bag;/// "Ảnh": anyone holding the link sees the photos switched to "Chia sẻ".
 bool get pics;
/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareCopyWith<Share> get copyWith => _$ShareCopyWithImpl<Share>(this as Share, _$identity);

  /// Serializes this Share to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Share;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Share&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.route, _this.route) || other.route == _this.route)&&(identical(other.routeFrom, _this.routeFrom) || other.routeFrom == _this.routeFrom)&&(identical(other.bag, _this.bag) || other.bag == _this.bag)&&(identical(other.pics, _this.pics) || other.pics == _this.pics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Share;
  return Object.hash(runtimeType,_this.id,_this.label,_this.createdAt,_this.expiresAt,_this.route,_this.routeFrom,_this.bag,_this.pics);
}

@override
String toString() {
  final _this = this as Share;
  return 'Share(id: ${_this.id}, label: ${_this.label}, createdAt: ${_this.createdAt}, expiresAt: ${_this.expiresAt}, route: ${_this.route}, routeFrom: ${_this.routeFrom}, bag: ${_this.bag}, pics: ${_this.pics})';
}


}

/// @nodoc
abstract mixin class $ShareCopyWith<$Res>  {
  factory $ShareCopyWith(Share value, $Res Function(Share) _then) = _$ShareCopyWithImpl;
@useResult
$Res call({
 String id, String label, String createdAt, String expiresAt, bool route, String? routeFrom, bool bag, bool pics
});




}
/// @nodoc
class _$ShareCopyWithImpl<$Res>
    implements $ShareCopyWith<$Res> {
  _$ShareCopyWithImpl(this._self, this._then);

  final Share _self;
  final $Res Function(Share) _then;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? createdAt = null,Object? expiresAt = null,Object? route = null,Object? routeFrom = freezed,Object? bag = null,Object? pics = null,}) {
  return _then(Share(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as bool,routeFrom: freezed == routeFrom ? _self.routeFrom : routeFrom // ignore: cast_nullable_to_non_nullable
as String?,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as bool,pics: null == pics ? _self.pics : pics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Share].
extension SharePatterns on Share {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Share value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Share() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Share value)  $default,){
final _that = this;
switch (_that) {
case _Share():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Share value)?  $default,){
final _that = this;
switch (_that) {
case _Share() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String createdAt,  String expiresAt,  bool route,  String? routeFrom,  bool bag,  bool pics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Share() when $default != null:
return $default(_that.id,_that.label,_that.createdAt,_that.expiresAt,_that.route,_that.routeFrom,_that.bag,_that.pics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String createdAt,  String expiresAt,  bool route,  String? routeFrom,  bool bag,  bool pics)  $default,) {final _that = this;
switch (_that) {
case _Share():
return $default(_that.id,_that.label,_that.createdAt,_that.expiresAt,_that.route,_that.routeFrom,_that.bag,_that.pics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String createdAt,  String expiresAt,  bool route,  String? routeFrom,  bool bag,  bool pics)?  $default,) {final _that = this;
switch (_that) {
case _Share() when $default != null:
return $default(_that.id,_that.label,_that.createdAt,_that.expiresAt,_that.route,_that.routeFrom,_that.bag,_that.pics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Share extends Share {
  const _Share({required this.id, required this.label, required this.createdAt, required this.expiresAt, this.route = false, this.routeFrom, this.bag = false, this.pics = false}): super._();
  factory _Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);

@override final  String id;
@override final  String label;
@override final  String createdAt;
@override final  String expiresAt;
@override@JsonKey() final  bool route;
/// First local day of the shared route ("YYYY-MM-DD"); null = today only.
@override final  String? routeFrom;
/// Anyone holding the link can open the bag.
@override@JsonKey() final  bool bag;
/// "Ảnh": anyone holding the link sees the photos switched to "Chia sẻ".
@override@JsonKey() final  bool pics;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareCopyWith<_Share> get copyWith => __$ShareCopyWithImpl<_Share>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Share&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.route, route) || other.route == route)&&(identical(other.routeFrom, routeFrom) || other.routeFrom == routeFrom)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.pics, pics) || other.pics == pics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,createdAt,expiresAt,route,routeFrom,bag,pics);
}

@override
String toString() {
    return 'Share(id: $id, label: $label, createdAt: $createdAt, expiresAt: $expiresAt, route: $route, routeFrom: $routeFrom, bag: $bag, pics: $pics)';
}


}

/// @nodoc
abstract mixin class _$ShareCopyWith<$Res> implements $ShareCopyWith<$Res> {
  factory _$ShareCopyWith(_Share value, $Res Function(_Share) _then) = __$ShareCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String createdAt, String expiresAt, bool route, String? routeFrom, bool bag, bool pics
});




}
/// @nodoc
class __$ShareCopyWithImpl<$Res>
    implements _$ShareCopyWith<$Res> {
  __$ShareCopyWithImpl(this._self, this._then);

  final _Share _self;
  final $Res Function(_Share) _then;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? createdAt = null,Object? expiresAt = null,Object? route = null,Object? routeFrom = freezed,Object? bag = null,Object? pics = null,}) {
  return _then(_Share(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as bool,routeFrom: freezed == routeFrom ? _self.routeFrom : routeFrom // ignore: cast_nullable_to_non_nullable
as String?,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as bool,pics: null == pics ? _self.pics : pics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
