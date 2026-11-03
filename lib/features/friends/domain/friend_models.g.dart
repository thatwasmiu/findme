// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Me _$MeFromJson(Map<String, dynamic> json) =>
    _Me(name: json['name'] as String, friendCode: json['friendCode'] as String);

Map<String, dynamic> _$MeToJson(_Me instance) => <String, dynamic>{
  'name': instance.name,
  'friendCode': instance.friendCode,
};

_Friend _$FriendFromJson(Map<String, dynamic> json) => _Friend(
  id: json['id'] as String,
  name: json['name'] as String,
  since: json['since'] as String,
  lastTs: json['lastTs'] as String?,
);

Map<String, dynamic> _$FriendToJson(_Friend instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'since': instance.since,
  'lastTs': instance.lastTs,
};

_Pending _$PendingFromJson(Map<String, dynamic> json) => _Pending(
  id: json['id'] as String,
  name: json['name'] as String,
  at: json['at'] as String,
);

Map<String, dynamic> _$PendingToJson(_Pending instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'at': instance.at,
};

_Relations _$RelationsFromJson(Map<String, dynamic> json) => _Relations(
  friends:
      (json['friends'] as List<dynamic>?)
          ?.map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Friend>[],
  incoming:
      (json['incoming'] as List<dynamic>?)
          ?.map((e) => Pending.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Pending>[],
  outgoing:
      (json['outgoing'] as List<dynamic>?)
          ?.map((e) => Pending.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Pending>[],
);

Map<String, dynamic> _$RelationsToJson(_Relations instance) =>
    <String, dynamic>{
      'friends': instance.friends,
      'incoming': instance.incoming,
      'outgoing': instance.outgoing,
    };

_LivePoint _$LivePointFromJson(Map<String, dynamic> json) => _LivePoint(
  id: json['id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lon: (json['lon'] as num).toDouble(),
  ts: json['ts'] as String,
);

Map<String, dynamic> _$LivePointToJson(_LivePoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lon': instance.lon,
      'ts': instance.ts,
    };
