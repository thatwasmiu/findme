// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Me {

 String get name; String get friendCode;
/// Create a copy of Me
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeCopyWith<Me> get copyWith => _$MeCopyWithImpl<Me>(this as Me, _$identity);

  /// Serializes this Me to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Me;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Me&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.friendCode, _this.friendCode) || other.friendCode == _this.friendCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Me;
  return Object.hash(runtimeType,_this.name,_this.friendCode);
}

@override
String toString() {
  final _this = this as Me;
  return 'Me(name: ${_this.name}, friendCode: ${_this.friendCode})';
}


}

/// @nodoc
abstract mixin class $MeCopyWith<$Res>  {
  factory $MeCopyWith(Me value, $Res Function(Me) _then) = _$MeCopyWithImpl;
@useResult
$Res call({
 String name, String friendCode
});




}
/// @nodoc
class _$MeCopyWithImpl<$Res>
    implements $MeCopyWith<$Res> {
  _$MeCopyWithImpl(this._self, this._then);

  final Me _self;
  final $Res Function(Me) _then;

/// Create a copy of Me
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? friendCode = null,}) {
  return _then(Me(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,friendCode: null == friendCode ? _self.friendCode : friendCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Me].
extension MePatterns on Me {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Me value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Me() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Me value)  $default,){
final _that = this;
switch (_that) {
case _Me():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Me value)?  $default,){
final _that = this;
switch (_that) {
case _Me() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String friendCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Me() when $default != null:
return $default(_that.name,_that.friendCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String friendCode)  $default,) {final _that = this;
switch (_that) {
case _Me():
return $default(_that.name,_that.friendCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String friendCode)?  $default,) {final _that = this;
switch (_that) {
case _Me() when $default != null:
return $default(_that.name,_that.friendCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Me implements Me {
  const _Me({required this.name, required this.friendCode});
  factory _Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

@override final  String name;
@override final  String friendCode;

/// Create a copy of Me
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeCopyWith<_Me> get copyWith => __$MeCopyWithImpl<_Me>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Me&&(identical(other.name, name) || other.name == name)&&(identical(other.friendCode, friendCode) || other.friendCode == friendCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,friendCode);
}

@override
String toString() {
    return 'Me(name: $name, friendCode: $friendCode)';
}


}

/// @nodoc
abstract mixin class _$MeCopyWith<$Res> implements $MeCopyWith<$Res> {
  factory _$MeCopyWith(_Me value, $Res Function(_Me) _then) = __$MeCopyWithImpl;
@override @useResult
$Res call({
 String name, String friendCode
});




}
/// @nodoc
class __$MeCopyWithImpl<$Res>
    implements _$MeCopyWith<$Res> {
  __$MeCopyWithImpl(this._self, this._then);

  final _Me _self;
  final $Res Function(_Me) _then;

/// Create a copy of Me
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? friendCode = null,}) {
  return _then(_Me(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,friendCode: null == friendCode ? _self.friendCode : friendCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Friend {

 String get id; String get name; String get since; String? get lastTs;
/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendCopyWith<Friend> get copyWith => _$FriendCopyWithImpl<Friend>(this as Friend, _$identity);

  /// Serializes this Friend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Friend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friend&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.since, _this.since) || other.since == _this.since)&&(identical(other.lastTs, _this.lastTs) || other.lastTs == _this.lastTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Friend;
  return Object.hash(runtimeType,_this.id,_this.name,_this.since,_this.lastTs);
}

@override
String toString() {
  final _this = this as Friend;
  return 'Friend(id: ${_this.id}, name: ${_this.name}, since: ${_this.since}, lastTs: ${_this.lastTs})';
}


}

/// @nodoc
abstract mixin class $FriendCopyWith<$Res>  {
  factory $FriendCopyWith(Friend value, $Res Function(Friend) _then) = _$FriendCopyWithImpl;
@useResult
$Res call({
 String id, String name, String since, String? lastTs
});




}
/// @nodoc
class _$FriendCopyWithImpl<$Res>
    implements $FriendCopyWith<$Res> {
  _$FriendCopyWithImpl(this._self, this._then);

  final Friend _self;
  final $Res Function(Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? since = null,Object? lastTs = freezed,}) {
  return _then(Friend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as String,lastTs: freezed == lastTs ? _self.lastTs : lastTs // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Friend].
extension FriendPatterns on Friend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friend value)  $default,){
final _that = this;
switch (_that) {
case _Friend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friend value)?  $default,){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String since,  String? lastTs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.id,_that.name,_that.since,_that.lastTs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String since,  String? lastTs)  $default,) {final _that = this;
switch (_that) {
case _Friend():
return $default(_that.id,_that.name,_that.since,_that.lastTs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String since,  String? lastTs)?  $default,) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.id,_that.name,_that.since,_that.lastTs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Friend implements Friend {
  const _Friend({required this.id, required this.name, required this.since, this.lastTs});
  factory _Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);

@override final  String id;
@override final  String name;
@override final  String since;
@override final  String? lastTs;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendCopyWith<_Friend> get copyWith => __$FriendCopyWithImpl<_Friend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friend&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.since, since) || other.since == since)&&(identical(other.lastTs, lastTs) || other.lastTs == lastTs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,since,lastTs);
}

@override
String toString() {
    return 'Friend(id: $id, name: $name, since: $since, lastTs: $lastTs)';
}


}

/// @nodoc
abstract mixin class _$FriendCopyWith<$Res> implements $FriendCopyWith<$Res> {
  factory _$FriendCopyWith(_Friend value, $Res Function(_Friend) _then) = __$FriendCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String since, String? lastTs
});




}
/// @nodoc
class __$FriendCopyWithImpl<$Res>
    implements _$FriendCopyWith<$Res> {
  __$FriendCopyWithImpl(this._self, this._then);

  final _Friend _self;
  final $Res Function(_Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? since = null,Object? lastTs = freezed,}) {
  return _then(_Friend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as String,lastTs: freezed == lastTs ? _self.lastTs : lastTs // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Pending {

 String get id; String get name; String get at;
/// Create a copy of Pending
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingCopyWith<Pending> get copyWith => _$PendingCopyWithImpl<Pending>(this as Pending, _$identity);

  /// Serializes this Pending to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Pending;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pending&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Pending;
  return Object.hash(runtimeType,_this.id,_this.name,_this.at);
}

@override
String toString() {
  final _this = this as Pending;
  return 'Pending(id: ${_this.id}, name: ${_this.name}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $PendingCopyWith<$Res>  {
  factory $PendingCopyWith(Pending value, $Res Function(Pending) _then) = _$PendingCopyWithImpl;
@useResult
$Res call({
 String id, String name, String at
});




}
/// @nodoc
class _$PendingCopyWithImpl<$Res>
    implements $PendingCopyWith<$Res> {
  _$PendingCopyWithImpl(this._self, this._then);

  final Pending _self;
  final $Res Function(Pending) _then;

/// Create a copy of Pending
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? at = null,}) {
  return _then(Pending(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Pending].
extension PendingPatterns on Pending {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pending value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pending() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pending value)  $default,){
final _that = this;
switch (_that) {
case _Pending():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pending value)?  $default,){
final _that = this;
switch (_that) {
case _Pending() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pending() when $default != null:
return $default(_that.id,_that.name,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String at)  $default,) {final _that = this;
switch (_that) {
case _Pending():
return $default(_that.id,_that.name,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String at)?  $default,) {final _that = this;
switch (_that) {
case _Pending() when $default != null:
return $default(_that.id,_that.name,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pending implements Pending {
  const _Pending({required this.id, required this.name, required this.at});
  factory _Pending.fromJson(Map<String, dynamic> json) => _$PendingFromJson(json);

@override final  String id;
@override final  String name;
@override final  String at;

/// Create a copy of Pending
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingCopyWith<_Pending> get copyWith => __$PendingCopyWithImpl<_Pending>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pending&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,at);
}

@override
String toString() {
    return 'Pending(id: $id, name: $name, at: $at)';
}


}

/// @nodoc
abstract mixin class _$PendingCopyWith<$Res> implements $PendingCopyWith<$Res> {
  factory _$PendingCopyWith(_Pending value, $Res Function(_Pending) _then) = __$PendingCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String at
});




}
/// @nodoc
class __$PendingCopyWithImpl<$Res>
    implements _$PendingCopyWith<$Res> {
  __$PendingCopyWithImpl(this._self, this._then);

  final _Pending _self;
  final $Res Function(_Pending) _then;

/// Create a copy of Pending
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? at = null,}) {
  return _then(_Pending(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Relations {

 List<Friend> get friends; List<Pending> get incoming; List<Pending> get outgoing;
/// Create a copy of Relations
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationsCopyWith<Relations> get copyWith => _$RelationsCopyWithImpl<Relations>(this as Relations, _$identity);

  /// Serializes this Relations to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Relations;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Relations&&const DeepCollectionEquality().equals(other.friends, _this.friends)&&const DeepCollectionEquality().equals(other.incoming, _this.incoming)&&const DeepCollectionEquality().equals(other.outgoing, _this.outgoing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Relations;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.friends),const DeepCollectionEquality().hash(_this.incoming),const DeepCollectionEquality().hash(_this.outgoing));
}

@override
String toString() {
  final _this = this as Relations;
  return 'Relations(friends: ${_this.friends}, incoming: ${_this.incoming}, outgoing: ${_this.outgoing})';
}


}

/// @nodoc
abstract mixin class $RelationsCopyWith<$Res>  {
  factory $RelationsCopyWith(Relations value, $Res Function(Relations) _then) = _$RelationsCopyWithImpl;
@useResult
$Res call({
 List<Friend> friends, List<Pending> incoming, List<Pending> outgoing
});




}
/// @nodoc
class _$RelationsCopyWithImpl<$Res>
    implements $RelationsCopyWith<$Res> {
  _$RelationsCopyWithImpl(this._self, this._then);

  final Relations _self;
  final $Res Function(Relations) _then;

/// Create a copy of Relations
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? friends = null,Object? incoming = null,Object? outgoing = null,}) {
  return _then(Relations(
friends: null == friends ? _self.friends : friends // ignore: cast_nullable_to_non_nullable
as List<Friend>,incoming: null == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<Pending>,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<Pending>,
  ));
}

}


/// Adds pattern-matching-related methods to [Relations].
extension RelationsPatterns on Relations {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Relations value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Relations() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Relations value)  $default,){
final _that = this;
switch (_that) {
case _Relations():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Relations value)?  $default,){
final _that = this;
switch (_that) {
case _Relations() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Friend> friends,  List<Pending> incoming,  List<Pending> outgoing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Relations() when $default != null:
return $default(_that.friends,_that.incoming,_that.outgoing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Friend> friends,  List<Pending> incoming,  List<Pending> outgoing)  $default,) {final _that = this;
switch (_that) {
case _Relations():
return $default(_that.friends,_that.incoming,_that.outgoing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Friend> friends,  List<Pending> incoming,  List<Pending> outgoing)?  $default,) {final _that = this;
switch (_that) {
case _Relations() when $default != null:
return $default(_that.friends,_that.incoming,_that.outgoing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Relations implements Relations {
  const _Relations({ List<Friend> friends = const <Friend>[],  List<Pending> incoming = const <Pending>[],  List<Pending> outgoing = const <Pending>[]}): _friends = friends,_incoming = incoming,_outgoing = outgoing;
  factory _Relations.fromJson(Map<String, dynamic> json) => _$RelationsFromJson(json);

 final  List<Friend> _friends;
@override@JsonKey() List<Friend> get friends {
  if (_friends is EqualUnmodifiableListView) return _friends;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_friends);
}

 final  List<Pending> _incoming;
@override@JsonKey() List<Pending> get incoming {
  if (_incoming is EqualUnmodifiableListView) return _incoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incoming);
}

 final  List<Pending> _outgoing;
@override@JsonKey() List<Pending> get outgoing {
  if (_outgoing is EqualUnmodifiableListView) return _outgoing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outgoing);
}


/// Create a copy of Relations
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationsCopyWith<_Relations> get copyWith => __$RelationsCopyWithImpl<_Relations>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelationsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Relations&&const DeepCollectionEquality().equals(other.friends, _friends)&&const DeepCollectionEquality().equals(other.incoming, _incoming)&&const DeepCollectionEquality().equals(other.outgoing, _outgoing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_friends),const DeepCollectionEquality().hash(_incoming),const DeepCollectionEquality().hash(_outgoing));
}

@override
String toString() {
    return 'Relations(friends: $friends, incoming: $incoming, outgoing: $outgoing)';
}


}

/// @nodoc
abstract mixin class _$RelationsCopyWith<$Res> implements $RelationsCopyWith<$Res> {
  factory _$RelationsCopyWith(_Relations value, $Res Function(_Relations) _then) = __$RelationsCopyWithImpl;
@override @useResult
$Res call({
 List<Friend> friends, List<Pending> incoming, List<Pending> outgoing
});




}
/// @nodoc
class __$RelationsCopyWithImpl<$Res>
    implements _$RelationsCopyWith<$Res> {
  __$RelationsCopyWithImpl(this._self, this._then);

  final _Relations _self;
  final $Res Function(_Relations) _then;

/// Create a copy of Relations
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? friends = null,Object? incoming = null,Object? outgoing = null,}) {
  return _then(_Relations(
friends: null == friends ? _self._friends : friends // ignore: cast_nullable_to_non_nullable
as List<Friend>,incoming: null == incoming ? _self._incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<Pending>,outgoing: null == outgoing ? _self._outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<Pending>,
  ));
}


}

// dart format on
